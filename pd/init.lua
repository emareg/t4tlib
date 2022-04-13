-- This Lua script is run every time the Lua interpreter is started when running
-- a Lua filter. It can be customized to load additional modules or to alter the
-- default modules.

function print_table(tab)
  for key, val in pairs(tab) do
    print(key, ": ", val)
  end
end


function file_exists(name)
   local f=io.open(name,"r")
   if f~=nil then io.close(f) return true else return false end
end

function starts_with(str, start)
  if type(str) ~= "string" then return end
  if (type(start) == "table") then
    for key, val in pairs(start) do
      if starts_with(str, val) then return true end
    end
  elseif (type(start) == "string") then
    return str:sub(1, #start) == start
  end 
end
