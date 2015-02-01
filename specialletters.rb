class SpecialLetters
	
	@@letters = {
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
		if @@letters.has_key?(letter)
			return @@letters[letter]
		else
			return letter
		end
	end

end