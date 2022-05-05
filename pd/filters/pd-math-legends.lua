--  Pandoc Filter to convert Paragraphs that start with certain keywords into boxes
-- Lua-Filter Documentation: https://pandoc.org/lua-filters.html

-- el.attr holds [identifier, classes, attributes]
-- Remember: Lua Lists (=table) start at index 1!


local system = require 'pandoc.system'

-- Settings
---------------------------------------------------

TRIGGER_Legend={"with", "where"}



-- Templates
---------------------------------------------------
ARITHMATEX = "<div class=\"arithmatex\">\\[%s\\]</div>"

DETAILS_START = [[
<details class="math-legend" markdown>
  <summary>
]]
SUMMARY_END = "\n</summary>"
DETAILS_END = "</details>"


-- Helper Functions
---------------------------------------------------
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

local function print_table(tab)
  for key, val in pairs(tab) do
    print(key, ": ", val)
  end
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



function Para(p)
  if FORMAT:match 'pdf' then return end
  -- print_table(el.content[1])
  if #p.content < 3 then return end
  if p.content[1]['t'] ~= "Math" then return end
  if p.content[2]['t'] ~= "SoftBreak" then return end
  if p.content[3]['t'] ~= "Str" then return end
  firstWord = p.content[3]['text']
  if firstWord == "where" or firstWord == "with" then
    -- print(p.content[1]['text'])
    -- print_table(p.content)
    head = pandoc.Para({p.content[1]})
    if FORMAT:match 'markdown' then
      head = pandoc.Para({pandoc.RawInline('html', ARITHMATEX:format(p.content[1]['text']))})
    end
    body = pandoc.Para({table.unpack(p.content, 3, #p.content)})
    return details(head, body, '')
  end
end


