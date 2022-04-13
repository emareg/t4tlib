-- Pandoc Filter to include other files via !INCLUDE "rel/file/path.md"
-- Lua-Filter Documentation: https://pandoc.org/lua-filters.html
-- Remember: Lua Lists (=table) start at index 1!


local system = require 'pandoc.system'

-- Settings
---------------------------------------------------

local HTML_FIG_T = [[
<figure>
  %s
</figure>
]]



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



function replaceImg(el)
  if not el.src then return end
  local ext = el.src:sub(-4,-1)
  if ext == ".svg" or ext == "html" then

    -- Get Caption 
    -- TODO: use el.caption and return Plain between HTML Blocks 
    -- print(el.caption, el.title)  
    -- el.caption or el.title or -- el.caption=table, title="fig"

    local file = io.open(el.src, "rb")
    -- print("Reading Image Source", el.src)
    if not file then return end
    html = file:read "*a"
    -- print("Read: ", html)
    if el.caption then
      fig_start = pandoc.RawBlock("html", "<figure id='"..el.identifier.."'>"..html.."\n<figcaption>")
      caption = pandoc.Plain(el.caption)
      fig_end = pandoc.RawBlock("html", "</figcaption>\n</figure>")
      return {fig_start, caption, fig_end}
    else
      if el.attributes['caption'] then
        caption = '\n<figcaption>'..el.attributes['caption']..'</figcaption>'
      else
        caption = ""
      end
      return pandoc.RawBlock("html", HTML_FIG_T:format(html..caption))
    end
  end
end


-- Include HTML and SVG Images directl
---------------------------------------------------
-- function Image(el)
--   if FORMAT ~= "html" then return end
--   return replaceImg(el)
-- end


function Para(el)
  if FORMAT == "html" and #el.c == 1 and el.c[1].t == "Image" then
    return replaceImg(el.content[1])
  end
end



