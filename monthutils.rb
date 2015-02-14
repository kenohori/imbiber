class MonthUtils

	@@number_to_abbreviated_month = {
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

	@@full_month_to_abbreviated_month = {
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

	def number_to_abbreviated_month(number)
		if @@number_to_abbreviated_month.has_key?(number) then
			@@number_to_abbreviated_month[number]
		else
			number
		end
	end

	def full_month_to_abbreviated_month(fullmonth)
		if @@full_month_to_abbreviated_month.has_key?(fullmonth) then
			@@full_month_to_abbreviated_month[fullmonth]
		else
			fullmonth
		end
	end
end