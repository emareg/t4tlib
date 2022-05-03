
-- have 2 lists: one for Wikipedia Links and one for Tex4TUM links


local T4T_DOUBLE_WORDS = {  "Binomial Distribution", "Differential Equation", "Kalman filter", "Servo motor", "Harmonic oscillation" }
local T4T_WORDS = { 
	"6LowPAN", "AES", "bool",
	"CoAP", "CMOS", "convolution", "Cpp", "CSS", 
	"Float", "geometry", "git", 
	"datetime", "DNS", "Haskell", "integral", "matrix", "Maxwell"
}

local WIKI_WORDS = {
	{"ACK", "A"}
}


function Para(el)
	local last_str=""
	return el:walk {
		Str = function(s)		
			local word = s.text  --:gsub('[,.%)]','')
			local two_words = last_str.." "..word
			-- print(word)
			for i, acro in pairs(T4T_DOUBLE_WORDS) do
				if word == acro then
					return pandoc.Link(acro, '/'..acro)
				end
			end
			for i, acro in pairs(T4T_WORDS) do
				if word == acro then
					return pandoc.Link(acro, '/'..acro)
				end
			end
			last_str = s.text
		end
	}
end
