class LocalisedText
	@@words = {
		:en => {
			:and => 'and',
			:In => 'In',
			:eds => 'eds.',
			:chapter => 'chapter',
			:pp => 'pp.'
		},
		:es => {
			:and => 'y',
			:In => 'En',
			:eds => 'eds.',
			:chapter => 'capítulo',
			:pp => 'pp.'
		}
	}

	@@months = {
		:en => {
			"jan" => "January",
			"feb" => "February",
			"mar" => "March",
			"apr" => "April",
			"may" => "May",
			"jun" => "June",
			"jul" => "July",
			"aug" => "August",
			"sep" => "September",
			"oct" => "October",
			"nov" => "November",
			"dec" => "December"
		},
		:es => {
			"jan" => "enero",
			"feb" => "febrero",
			"mar" => "marzo",
			"apr" => "abril",
			"may" => "mayo",
			"jun" => "junio",
			"jul" => "julio",
			"aug" => "agosto",
			"sep" => "septiembre",
			"oct" => "octubre",
			"nov" => "noviembre",
			"dec" => "diciembre"
		}
	}

	def initialize(locale = :en)
		@locale = locale
	end

	def localise(word)
		@@words[@locale][word]
	end

	def localisedmonth(month)
		@@months[@locale][month]
	end
end