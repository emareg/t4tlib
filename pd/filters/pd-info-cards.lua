--  Pandoc Filter to convert Paragraphs that start with certain keywords into boxes
-- Lua-Filter Documentation: https://pandoc.org/lua-filters.html

-- el.attr holds [identifier, classes, attributes]
-- Remember: Lua Lists (=table) start at index 1!


local system = require 'pandoc.system'

-- Settings
---------------------------------------------------

TRIGGER_DETAILS_HINT={"Example:", "Details:", "Q:"}
TRIGGER_DETAILS_INFO={"Legend:", "Details:"}
TRIGGER_DETAILS_IMPORTANT={"Explanation:"}
TRIGGER_DETAILS_WARNING={}


local CARD_MAP = {
  -- class  = trigger words
  abstract  = {sym = '💡 ', trigger={"Abstract:", "TL;DR:"}},
  hint      = {sym = '💡 ', trigger={"Example:", "Hint:", "Tipp:"}},
  info      = {sym = 'ℹ️ ', trigger={"Info:", "Note:", "Notice:", "Explanation:"}},
  important = {sym = '❗ ', trigger={"Attention:", "Important:", "Remember:"}},
  warning   = {sym = '⚠️ ', trigger={"Warn:", "Warning:", "Caution:", "Danger:", "Error:"}}
}


local DETAILS_MAP = {
  -- class  = trigger words
  example   = {"Example", "Use-case"},
  info      = {"Info", "Information", "Note", "Notice"},
  tip       = {"Explanation", "Details", "Remember"}
}


-- Templates
---------------------------------------------------
DETAILS_START = [[
<details class="%s" markdown>
  <summary markdown>]]
SUMMARY_END = "</summary>"
DETAILS_END = "</details>\n"

P_ADOM="<p class=\"admonition-title\" markdown>%s</p>"


-- Helper Functions
---------------------------------------------------
function file_exists(name)
   local f=io.open(name,"r")
   if f~=nil then io.close(f) return true else return false end
end

local function starts_with(str, start)
  if type(str) ~= "string" then return end
  if (type(start) == "table") then
    for key, val in pairs(start) do
      if starts_with(str, val) then return true end
    end
  elseif (type(start) == "string") then
    return str:sub(1, #start) == start
  end 
end

local function write_file(fname, text)
  local f = io.open(fname, 'w')
  f:write(text)
  f:close()
end

local function print_table(tab)
  for key, val in pairs(tab) do
    print(key, ": ", val)
  end
end


--  create div card
local function card(heading, body, class)
  if FORMAT:match 'markdown' then
    -- divHead = pandoc.Para(pandoc.Str(heading:sub(4)), {class='admonition-title', markdown=''})
    divHead = pandoc.RawBlock('html', P_ADOM:format( pandoc.utils.stringify(heading ) ) )
    divBody = pandoc.Para(body)
    -- return { pandoc.Para({ pandoc.Str("???+ "..class..' "'..heading..'"') }), pandoc.BlockQuote({table.unpack(body.content)}) }
  else
    parHead = pandoc.Para(pandoc.Strong(heading))
    divHead = pandoc.Div(parHead, {class='card-header admonition-title'})
    divBody = pandoc.Div({body}, {class='card-body'})
  end 
  if FORMAT:match 'gfm' then
    return pandoc.BlockQuote({pandoc.Para({pandoc.Strong(heading), table.unpack(body.content)})})
  end 
  return pandoc.Div({divHead, divBody}, {class = 'card admonition '..class, markdown=''})
end


-- create details/summary
local function details(heading, body, class)
  if type(heading) == "string" then 
    heading = pandoc.Plain(pandoc.Str(heading))
  end
  if FORMAT:match 'gfm' then
    detailsStart = pandoc.RawBlock('html', DETAILS_START:format(class)..'👆 <strong><ins>')
    summaryEnd = pandoc.RawBlock('html', '</ins></strong>'..SUMMARY_END)
  else
    detailsStart = pandoc.RawBlock('html', DETAILS_START:format(class))
    summaryEnd = pandoc.RawBlock('html', SUMMARY_END)
  end
  detailsEnd = pandoc.RawBlock('html', DETAILS_END)
  return {detailsStart, pandoc.Plain(heading.content), summaryEnd, body, detailsEnd}
  -- return {pandoc.LineBlock({detailsStart, table.unpack(heading.content), summaryEnd}), body, detailsEnd}
end



-- returns table {str(firstWord), {firstLine}, {remainder} }
function parse_para(p)
  if #p.content < 3 then return end
  if p.content[1]['t'] ~= "Str" then return end
  heading = {p.content[1]}
  break_idx = 2
  for idx, val in pairs(p.content) do
    if val['t'] == "SoftBreak" then 
      break_idx = idx
      if break_idx > 2 then
        heading = {table.unpack(p.content, 2, break_idx)}
      end
      break
    end
  end
  return {p.content[1]['text'], heading, {table.unpack(p.content, break_idx+1, #p.content)}}
end


function BlockQuote(el)
  p = parse_para(el.content[1])
  if not p then return end
  for key, val in pairs(CARD_MAP) do
    if starts_with(p[1], val.trigger) then
      bcStart = pandoc.RawBlock('html', "<Blockquote class=\""..key.."\">")
      bcEnd = pandoc.RawBlock('html', '</Blockquote>')
      return {bcStart, el.content[1], bcEnd}
    end
  end
end


function Para(el)
  if #el.content < 3 then return end
  p = parse_para(el)
  if not p then return end
  -- print(table.unpack(p))
  if FORMAT:match 'html' or FORMAT:match 'gfm' or FORMAT:match 'markdown' then
    -- print_table(el.content[1])
    if p[1] == "Q:" and p[3][1]['t'] == "Str" and p[3][1]['text'] == "A:" then
      head = pandoc.Para(p[2])
      body = pandoc.Para({table.unpack(p[3], 3)})
      return details(head, body, 'question')
    end
    if p[1] == "Details:" then
      return details(pandoc.Para(p[2]), pandoc.Para(p[3]), 'info')
    end
    for key, val in pairs(CARD_MAP) do
      if starts_with(p[1], val.trigger) then
        return card(p[2], p[3], key)
      end
    end
  end
end



function Pandoc(doc)
  active_head_lvl = 0
  blocks = doc.blocks:walk {
    Header = function(h)
      local finish
      if h.level <= active_head_lvl then
        active_head_lvl = 0
        finish = pandoc.RawBlock('html', DETAILS_END)
      end
      htab = parse_para(h)
      if not htab then 
        if finish then return {finish, h} end
        return
      end
      for key, triggers in pairs(DETAILS_MAP) do
        if starts_with(htab[1], triggers) then
          detailsStart = pandoc.RawBlock('html', DETAILS_START:format(key))
          summaryEnd = pandoc.RawBlock('html', SUMMARY_END)
          active_head_lvl = h.level
          if finish then
            return {finish, detailsStart, pandoc.Para(h.content), summaryEnd}
          else
            return {detailsStart, pandoc.Para(h.content), summaryEnd}
          end
        end
      end
      if finish then return {finish, h} end
    end
  }
  return pandoc.Pandoc(blocks, doc.meta)
end