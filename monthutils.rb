class MonthUtils

	@@numbertoabbreviatedmonth = {
		"1" => "jan",
		"2" => "feb",
		"3" => "mar",
		"4" => "apr",
		"5" => "may",
		"6" => "jun",
		"7" => "jul",
		"8" => "aug",
		"9" => "sep",
		"10" => "oct",
		"11" => "nov",
		"12" => "dec"
	}

	@@fullmonthtoabbreviatedmonth = {
		"january" => "jan",
		"february" => "feb",
		"march" => "mar",
		"april" => "apr",
		"may" => "may",
		"june" => "jun",
		"july" => "jul",
		"august" => "aug",
		"september" => "sep",
		"october" => "oct",
		"november" => "nov",
		"december" => "dec"
	}

	def numbertoabbreviatedmonth(number)
		if @@numbertoabbreviatedmonth.has_key?(number) then
			@@numbertoabbreviatedmonth[number]
		else
			number
		end
	end

	def fullmonthtoabbreviatedmonth(fullmonth)
		if @@fullmonthtoabbreviatedmonth.has_key?(fullmonth) then
			@@fullmonthtoabbreviatedmonth[fullmonth]
		else
			fullmonth
		end
	end
end