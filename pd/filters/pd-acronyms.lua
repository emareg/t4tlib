-- Pandoc Filter to add acryonyms
-- Lua-Filter Documentation: https://pandoc.org/lua-filters.html

-- load local files magic
package.path = debug.getinfo(1,"S").source:match[[^@?(.*[\/])[^\/]-$]] .."?.lua;".. package.path


local acronyms = require('acronyms')


local HTML_TEMPLATE='<abbr title="%s">%s</abbr>'
local TEX_TEMPLATE='\\gls{%s}'


function Para(el)
	return el:walk {
		Str = function(s)		
			local word = s.text  --:gsub('[,.%)]','')
			if FORMAT:match 'html' then
				for i, acro in pairs(acronyms) do
					if word == acro[1] then
						return pandoc.RawInline('html', HTML_TEMPLATE:format(acro[2], acro[1]))
					end
				end
			end 
			if FORMAT:match 'tex' then
				for i, acro in pairs(acronyms) do
					if word == acro[0] then
						return pandoc.RawInline('tex', TEX_TEMPLATE:format(acro[1]))
					end
				end
			end 
		end
	}
end