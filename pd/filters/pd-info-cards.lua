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
  hint      = {sym = '💡 ', trigger={"Example:", "Hint:", "Tipp:"}},
  info      = {sym = 'ℹ️ ', trigger={"Info:", "Note:", "Notice:"}},
  important = {sym = '❗ ', trigger={"Attention:", "Important:", "Remember:"}},
  warn   = {sym = '⚠️ ', trigger={"Warn:", "Warning:", "Caution:", "Danger:", "Error:"}}
}



-- Templates
---------------------------------------------------
DETAILS_START = [[
<details class="%s">
  <summary>]]
SUMMARY_END = "</summary>"
DETAILS_END = "</details>"


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
  parHead = pandoc.Para(pandoc.Strong(heading))
  divHead = pandoc.Div(parHead, {class='card-header'})
  divBody = pandoc.Div({body}, {class='card-body'})
  if FORMAT:match 'gfm' then
    return pandoc.BlockQuote({pandoc.Para({pandoc.Strong(heading), table.unpack(body.content)})})
  end 
  return pandoc.Div({divHead, divBody}, {class = 'card '..class})
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



function Para(el)
  -- print_table(el.content[1])
  if not el.content[1] then return end
  if not el.content[1]['t'] == "Str" then return end
  firstWord = el.content[1]['text']
  if FORMAT:match 'html' or FORMAT:match 'gfm' then
    -- print_table(el.content[1])
    if starts_with(firstWord, "Q:") then
      for key, val in pairs(el.content) do
        if val['t'] == "Str" and val['text'] == "A:" then
          head = pandoc.Para({table.unpack(el.content, 2, key - 1)})
          body = pandoc.Para({table.unpack(el.content, key+1, #el.content)})
          return details(head, body, '')
        end
      end
      return nil
    end
    for key, val in pairs(CARD_MAP) do
      if starts_with(firstWord, val.trigger) then
        -- todo: check if contains SoftBreak, if yes make that the heading or check if Strong
        table.remove(el.content, 1)
        return card(val.sym..firstWord, el, key)
      end
    end
  end
end


