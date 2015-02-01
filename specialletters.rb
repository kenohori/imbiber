class SpecialLetters
	
	@@letters = {
		"---" => "—",
		"--" => "–",

		"\\\"a" => "ä",
		"\\\"e" => "ë",
		"\\\"i" => "ï",
		"\\\"o" => "ö",
		"\\\"u" => "ü",

		"\\\'a" => "á",
		"\\\'e" => "é",
		"\\\'i" => "í",
		"\\\'o" => "ó",
		"\\\'u" => "ú",

		"\\\^a" => "â",
		"\\\^e" => "ê",
		"\\\^i" => "î",
		"\\\^o" => "ô",
		"\\\^u" => "û" 
	}

	def convert(letter)
		if @@letters.has_key?(letter) then
			return @@letters[letter]
		elsif letter.length == 2 and letter[0] == "\\" then
			return letter[1]
		else
			puts "Warning: not supported letter " + letter
			return letter
		end
	end

end