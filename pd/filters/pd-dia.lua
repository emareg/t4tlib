--  Pandoc Filter to convert code blocks to diagrams
-- Lua-Filter Documentation: https://pandoc.org/lua-filters.html

-- el.attr holds [identifier, classes, attributes]


local system = require 'pandoc.system'


-- Settings
---------------------------------------------------

-- Figure Dimensions
local WIDTH_IN='10'  -- default figure width in Inch, px ≈ in * 100
local HEIGHT_IN='5'

-- Diagram directories
local TMPDIR = "./"
local BUILDDIR = "./"
local DIADIR = "dia/"   -- relative path appended to BUILDDIR | TMPDIR


-- Coonstants
---------------------------------------------------

-- Input Extensions
local PY_EXT  = 'py'
local R_EXT   = 'R'
local PU_EXT  = 'pu'
local TEX_EXT = 'tex'

-- Output Extensions
local JS_EXT  = 'js'
local SVG_EXT  = 'svg'
local PDF_EXT  = 'pdf'
local HTML_EXT = 'html'


-- get PlantUMLJar
local PLANTUMLJAR = os.getenv("PLANTUMLJAR") or 'plantuml.jar'


-- Execution Commands
---------------------------------------------------
local PY_CMD = 'python3 %s'
local R_CMD  = 'Rscript --quiet --no-save %s'
local PU_CMD  = 'cat %s | java -jar '..PLANTUMLJAR..' -tsvg -pipe > %s'
local TEX_CMD  = [[
  in=%s; out=%s;
  outdir=`echo $in | sed 's!\\(.*\\)\\/.*!\\1!'`;
  pdf=`echo $in | sed 's/\\(.*\\.\\)tex/\\1pdf/'`;
  echo "${pdf}";
  echo "${out}";
  texfot pdflatex -output-directory=${outdir} ${in}; 
  inkscape --without-gui --file="${pdf}" --export-plain-svg="${out}"
]]


-- Default Python Imports
local PY_IMPORTS = [[
import numpy as np
import pandas as pd
import scipy.stats as st
]]

-- HTML Figure Template
local HTML_FIG_T = [[
<figure>
  %s
</figure>
]]


local MATPLOTLIB_T = PY_IMPORTS..[[
import matplotlib.pyplot as plt
%s
plt.savefig('%s',)
]]


local BOKEH_T = PY_IMPORTS..[[
from bokeh.io import export, save
from bokeh.models import Model, WheelZoomTool, Slider
from bokeh.resources import CDN, Resources
from bokeh.embed import autoload_static
from bokeh.plotting import figure
%s
__models=[obj for obj in globals().values() if isinstance(obj, Model)]
__fig=[obj for obj in __models if obj.__class__.__name__ == "Figure"][-1]
__fig.toolbar.active_scroll = __fig.select_one(WheelZoomTool)
__fig.toolbar_location="above"
__fig.toolbar.logo = None
__fig.outline_line_color = None
__fig.legend.click_policy="mute"
__layouts = [obj for obj in __models if obj.__class__.__name__ == "Row"]
__currplot=__layouts[-1] if __layouts else __fig
]]

local BOKEH_JS_T = BOKEH_T..[[
__path="%s"
js, tag = autoload_static(__currplot, CDN, __path)
tag = tag.replace('src="{}"'.format(__path), '')
tag = tag.replace('</script>', js+'</script>')
with open(__path, "w") as _f:
    _f.write(tag)
]]

local BOKEH_SVG_T = BOKEH_T..[[
__current_model.output_backend="svg"; export.export_svg(__currplot, filename=r"%s")
]]
local BOKEH_HTML_T = BOKEH_T..[[
save(__currplot, filename="%s", resources=CDN)
]]



local PLOTLY_PY_T = PY_IMPORTS..[[
import plotly.graph_objects as go
%s
__currplot = next(obj for obj in globals().values() if type(obj) == go.Figure)
config={
  'displaylogo': False, 
  'scrollZoom': True, 
  'toImageButtonOptions': {'format': 'svg'},
  'modeBarButtonsToRemove': ['select2d','lasso2d', 'resetScale2d',]
}
__axis={ 'showgrid':True, 'gridwidth':1, 'gridcolor':'#eeeeee' }
__currplot.update_layout(template='simple_white', xaxis=__axis, yaxis=__axis)
__currplot.write_html("%s", include_plotlyjs="cdn", config=config)
]]


local GGPLOT2_T = [[
# init GGploT
library(ggplot2)
t4ttheme <- ggplot2::theme( 
  panel.grid.major = element_line(color = "gray"),
  panel.grid.minor = element_line(color = "gray", linetype="dotted")
)
theme_set(theme_classic() + t4ttheme)
%s
ggsave("%s", plot = last_plot(), width=]]..WIDTH_IN..', height='..HEIGHT_IN..')'



local TIKZ_T = [[
\documentclass{standalone}
\usepackage{xcolor}
\usepackage{tikz}
\usepackage{pgfplots}
\begin{document}
\nopagecolor
%s
\end{document}
%s
]]


local PLANTUML_T = "%s" 




-- Helper Functions
---------------------------------------------------
function addSlash(dir)
  if dir:sub(-1,-1) ~= "/" then return dir.."/" else return dir end
end

function file_exists(name)
   local f=io.open(name,"r")
   if f~=nil then io.close(f) return true else return false end
end

local function print_table(tab)
  for key, val in pairs(tab) do
    print(key, ": ", val)
  end
end




-- Plotter Map
---------------------------------------------------
local PLOT_MAP = {
  -- plotter    = command,      extra code,        file extension (in,out)
  matplotlib    = {cmd=PY_CMD,  code=MATPLOTLIB_T, inext=PY_EXT,  outext=SVG_EXT },
  bokeh         = {cmd=PY_CMD,  code=BOKEH_HTML_T, inext=PY_EXT,  outext=HTML_EXT},
  plotly_python = {cmd=PY_CMD,  code=PLOTLY_PY_T,  inext=PY_EXT,  outext=HTML_EXT},
  ggplot2       = {cmd=R_CMD,   code=GGPLOT2_T,    inext=R_EXT,   outext=SVG_EXT },
  plantuml      = {cmd=PU_CMD,  code=PLANTUML_T,   inext=PU_EXT,  outext=SVG_EXT },
  tikz          = {cmd=TEX_CMD, code=TIKZ_T,       inext=TEX_EXT, outext=SVG_EXT },
}


-- Plotting Function, returns Pandoc Element
---------------------------------------------------
local function plotBlock(el, plotter)
  -- Use element ID as filename or SHA1
  identifier = el.identifier
  if identifier == "" then 
    identifier = pandoc.sha1(el.text)
  end

  -- Determine Paths
  local tmppath = TMPDIR..identifier..'.'..plotter.inext
  local relpath = DIADIR ..  identifier .. '.'..plotter.outext
  local abspath = BUILDDIR .. relpath
  --if file_exists(abspath) then return end   -- do not generate if file exists

  -- Get Caption
  caption = el.attributes['caption']
  if not caption then caption = "" end

  local f = io.open(tmppath, 'w')
  f:write(plotter.code:format(el.text, abspath))
  f:close()
  -- print("\nExecute", plotter.cmd:format(tmppath, abspath))
  os.execute(plotter.cmd:format(tmppath, abspath))

  if string.find(FORMAT, "html") and (plotter.outext == HTML_EXT or plotter.outext == SVG_EXT) then
    local file = io.open(abspath, "rb")
    if not file then return el end
    if caption ~= "" then caption = '<figcaption>'..caption..'</figcaption>' end
    html = file:read "*a"
    return pandoc.RawBlock(HTML_EXT, HTML_FIG_T:format(html..caption))
  else
    return pandoc.Para({pandoc.Image(caption, relpath)})
  end
end



-- get dir names
function Meta(m)
  if m.tmpdir then TMPDIR = addSlash(m.tmpdir) end
  if m.builddir then BUILDDIR = addSlash(m.builddir) end
  if m.reldiadir then DIADIR = addSlash(m.reldiadir) end
  -- should this be done by toolchain? No measured overhead.
  os.execute('mkdir -p '..TMPDIR)    
  os.execute('mkdir -p '..BUILDDIR..DIADIR)
end



function CodeBlock(el)
  -- if not next(el.classes) then return end   -- ```python has class "python"

  for _,cls in pairs(el.classes) do         -- iterate over class names
    for name,plotter in pairs(PLOT_MAP) do  -- iterate over plotters

      if cls == name then                   -- check for match
        return plotBlock(el, plotter)
      end

    end
  end

  -- if wasFound then
  --   if FORMAT:match 'html' then
  --     -- print(abspath)
  --     local file = io.open(abspath, "rb") -- r read mode and b binary mode
  --     if not file then return el end
  --     return pandoc.RawBlock('html', file:read "*a")
  --   else
  --     return pandoc.Para({pandoc.Image(caption, relpath)})
  --   end
  -- else
  --   return el
  -- end
end

-- Change Filter Order
return {
  { Meta = Meta },  -- (1)
  { CodeBlock = CodeBlock }     -- (2)
}