--  Pandoc Filter to convert Paragraphs that start with certain keywords into boxes
-- Lua-Filter Documentation: https://pandoc.org/lua-filters.html



local system = require 'pandoc.system'


function Pandoc(doc)
  if not doc.meta.title then return end
  heading = pandoc.Header(1, doc.meta.title)
  table.insert(doc.blocks, 1, heading)
  return pandoc.Pandoc(doc.blocks, doc.meta)
end

