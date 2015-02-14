#!/usr/bin/ruby

require 'pp'
require 'parslet'
require 'parslet/convenience'

require_relative 'specialletters'
require_relative 'monthutils'
require_relative 'localisedtext'

class DocumentParser < Parslet::Parser

	def stri(str)
		key_chars = str.split(//)
	    key_chars.collect! { |char| match["#{char.upcase}#{char.downcase}"] }.
		reduce(:>>)
	end

	root(:document)

	rule(:whitespace) { match['\s\n\r'].repeat(1) }
	rule(:whitespace?) { whitespace.maybe }
	rule(:bracketedtext) { str('{') >> (match['^{}'] | bracketedtext).repeat >> str('}') }
	rule(:parenthesisedtext) { str('(') >> (str('\)') | match['^)']).repeat >> str(')') }
	rule(:newline) { str("\n") >> str("\r").maybe }

	rule(:document) { anyonething.repeat }
	rule(:anyonething) { nothing | something }
	rule(:nothing) { (str('@').absent? >> any).repeat(1) }
	rule(:something) { comment | string | preamble | entry.as(:entry) }

	rule(:comment) { str('@') >> stri('comment') >> (newline.absent? >> any).repeat >> newline }
	rule(:string) { str('@') >> stri('string') >> whitespace? >> (bracketedtext | parenthesisedtext) }
	rule(:preamble) { str('@') >> stri('preamble') >> whitespace? >> (bracketedtext | parenthesisedtext) }

	rule(:entry) { str('@') >> entryclass.as(:class) >> whitespace? >> entrycontents }
	rule(:entryclass) { match['^\s\n\r{},='].repeat(1) }
	rule(:entrycontents) { str('{') >> whitespace? >> entrykey.as(:key) >> whitespace? >> str(',') >> whitespace? >> entryfields.as(:fields) >> str(',').maybe >> whitespace? >> str('}') }
	rule(:entrykey) { match['^\s\n\r{},='].repeat(1) }
	rule(:entryfields) { entryfield.as(:field) >> whitespace? >> (str(',') >> whitespace? >> entryfield.as(:field) >> whitespace?).repeat }
	rule(:entryfield) { entryfieldname.as(:name) >> whitespace? >> str('=') >> whitespace? >> (bracketedvalue | quotedvalue | plainvalue.as(:value)).repeat }
	rule(:entryfieldname) { (match['^\s\n\r{},='] | bracketedtext).repeat(1) }

	rule(:bracketedvalue) { str('{') >> (match['^{}'] | bracketedtext).repeat.as(:value) >> str('}') }
	rule(:quotedvalue) { str('"') >> (match['^"{}'] | bracketedtext).repeat.as(:value) >> str('"') }
	rule(:plainvalue) { match['a-zA-Z0-9'].repeat(1) }
	
end

class AuthorsParser < Parslet::Parser

	root(:authorslist)

	rule(:whitespace) { match['\s\n\r'].repeat(1) }
	rule(:whitespace?) { whitespace.maybe }
	rule(:bracketedtext) { str('{') >> (match['^{}'] | bracketedtext).repeat >> str('}') }

	rule(:authorslist) { (whitespace | str('and ') | author.as(:author)).repeat }
	rule(:author) { (str(' and ').absent? >> (match['^{}'] | bracketedtext)).repeat(1) }

end

class NameParser < Parslet::Parser

	root(:name)

	rule(:whitespace) { match['\s\n\r'].repeat(1) }
	rule(:bracketedtext) { str('{') >> (pseudoletter | bracketedtext | whitespace.as(:space)).repeat >> str('}') }

	rule(:name) { (word | whitespace | str(',').as(:comma)).repeat.as(:name) }
	rule(:word) { (pseudoletter | bracketedtext).repeat(1).as(:word) | str('.') }
	rule(:pseudoletter) { specialletter.as(:specialletter) | letter.as(:letter) }
	rule(:letter) { match['a-zA-Z'] }
	rule(:specialletter) { str('---') | str('--') | (str('\\') >> str('&')) | (str('\\') >> modifier >> letter) }
	rule(:modifier) { str("\'") | str("\"") | str("\^") }

end

class NameTransformer < Parslet::Transform

	def initialize(nameformat = :firstlast)
		super()
		@@nameformat = nameformat
		@@sl = SpecialLetters.new
	end

	rule(:letter => simple(:l)) { l.to_s }
	rule(:specialletter => simple(:l)) { @@sl.convert(l.to_s) }
	rule(:space => simple(:s)) { " " }
	rule(:comma => simple(:c)) { "," }
	rule(:word => sequence(:w)) {
		word = w.join("")
		if word.length == 1 and word[0].upcase == word[0] then
			word << "."
		end
		word
	}
	
	rule(:name => subtree(:s)) {
		commas = 0
		s.each do |token|
			if token == "," then
				commas += 1
			end
		end
		case commas
		when 0
			first = s[0..-2].join(" ")
			last = s[-1]
			case @@nameformat
			when :firstlast
				first + " " + last
			when :lastfirst
				last + ", " + first
			end
		when 1
			first = []
			last = []
			commassofar = 0
			s.each do |token|
				if token == "," then
					commassofar += 1
				elsif commassofar == 0
					last.push(token)
				else
					first.push(token)
				end
			end
			case @@nameformat
			when :firstlast
				first.join(" ") + " " + last.join(" ")
			when :lastfirst
				last.join(" ") + ", " + first.join(" ")
			end
		end
	}
end

class TextParser < Parslet::Parser

	root(:text)

	rule(:whitespace) { match['\s\n\r'].repeat(1) }
	rule(:bracketedtext) { str('{') >> (pseudoletterpreservecase | bracketedtext | whitespace.as(:space)).repeat >> str('}') }

	rule(:text) { (whitespace | word).repeat.as(:text) }
	rule(:word) { (pseudoletter | bracketedtext).repeat(1).as(:word) }
	rule(:pseudoletter) { specialletter.as(:specialletter) | letter.as(:letter) }
	rule(:pseudoletterpreservecase) { specialletter.as(:specialletterpreservecase) | letter.as(:letterpreservecase) }
	rule(:letter) { match['^{}\\\\ '] }
	rule(:specialletter) { str('---') | str('--') | (str('\\') >> str('&')) | (str('\\') >> modifier >> letter) }
	rule(:modifier) { str("\'") | str("\"") | str("\^") }

end

class TextTransformer < Parslet::Transform

	def initialize(casetouse = :unchanged)
		super()
		@@casetouse = casetouse
		@@sl = SpecialLetters.new
	end

	rule(:letter => simple(:l)) { 
		case @@casetouse
		when :sentence
			l.to_s.downcase
		when :title
			l.to_s.downcase
		when :unchanged
			l.to_s
		end

	}

	rule(:specialletter => simple(:l)) {
		case @@casetouse
		when :sentence
			@@sl.convert(l.to_s.downcase)
		when :title
			@@sl.convert(l.to_s.downcase)
		when :unchanged
			@@sl.convert(l.to_s)
		end
	}

	rule(:letterpreservecase => simple(:l)) { l.to_s }
	rule(:specialletterpreservecase => simple(:l)) { @@sl.convert(l.to_s) }

	rule(:word => sequence(:w)) {
		case @@casetouse
		when :sentence
			w.join("")
		when :title
			word = w.join("")
			word = word[0].upcase + word[1..-1]
		when :unchanged
			w.join("")
		end
	}

	rule(:text => sequence(:t)) {
		case @@casetouse
		when :sentence
			text = t.join(" ")
			text = text[0].upcase + text[1..-1]
			text
		when :title
			t.join(" ")
		when :unchanged
			t.join(" ")
		end
	}

end

class MonthParser < Parslet::Parser

	def stri(str)
		key_chars = str.split(//)
	    key_chars.collect! { |char| match["#{char.upcase}#{char.downcase}"] }.
		reduce(:>>)
	end

	root(:number)

	rule(:number) { digit.repeat(1).as(:number) | monthname }
	rule(:digit) { match['0-9'] }
	rule(:monthname) { abbreviatedmonthname.as(:abbreviatedmonthname) | fullmonthname.as(:fullmonthname) }
	rule(:abbreviatedmonthname) { stri('jan') | stri('feb') | stri('mar') | stri('apr') | stri('may') | stri('jun') | stri('jul') | stri('aug') | stri('sep') | stri('oct') | stri('nov') | stri('dec') }
	rule(:fullmonthname) { stri('january') | 
	                       stri('february') |
	                       stri('march') |
	                       stri('april') |
	                       stri('may') |
	                       stri('june') |
	                       stri('july') |
	                       stri('august') |
	                       stri('september') |
	                       stri('october') |
	                       stri('november') |
	                       stri('december') }
end

class MonthTransformer < Parslet::Transform
	mu = MonthUtils.new

	rule(:abbreviatedmonthname => simple(:amn)) { amn.to_s }
	rule(:number => simple(:n)) { mu.number_to_abbreviated_month(n) }
end

class Imbiber
	def initialize(options = Hash.new)
		@entries = {}
		@options = {
			:lang => :en,
			:nameformat => :firstlast,
			:titlecase => :sentence
		}
		options.each do |key, value|
			@options[key] = value
		end

		@lt = LocalisedText.new(@options[:lang])
	end

	def to_s
		@entries.to_s
	end

	def entries
		@entries
	end

	def list_to_string(l)
		case l.length
		when 0
			return ""
		when 1
			return l[0]
		when 2
			return l[0] + ' ' + @lt.localise(:and) + ' ' + l[1]
		else
			return l[0..-2].join(', ') + ' ' + @lt.localise(:and) + ' ' + l[-1]
		end
	end

	def read(path)
		text = File.read(path)
		entriestree = DocumentParser.new.parse(text)
		entriestree.each do |entrybranch|
			key = entrybranch[:entry][:key].to_sym

			# Repeated key, skip
			if @entries.has_key?(key) then
				next
			end

			# Put in nicely formatted fields
			@entries[key] = {}
			@entries[key][:class] = entrybranch[:entry][:class]
			entrybranch[:entry][:fields].each do |field|
				# puts field[:field][0][:name].to_s.downcase
				case field[:field][0][:name].to_s.downcase
				when "author"
					# puts field[:field][1][:value].to_s
					authorstree = AuthorsParser.new.parse(field[:field][1][:value].to_s)
					@entries[key][:author] = []
					authorstree.each do |author|
						nametree = NameTransformer.new(@options[:nameformat]).apply(NameParser.new.parse(author[:author].to_s))
						@entries[key][:author].push(nametree)
					end
				when "editor"
					editorstree = AuthorsParser.new.parse(field[:field][1][:value].to_s)
					@entries[key][:editor] = []
					editorstree.each do |editor|
						nametree = NameTransformer.new(@options[:nameformat]).apply(NameParser.new.parse(editor[:author].to_s))
						@entries[key][:editor].push(nametree)
					end
				when "title"
					titletree = TextTransformer.new(@options[:titlecase]).apply(TextParser.new.parse(field[:field][1][:value].to_s))
					@entries[key][:title] = titletree.to_s
				when "month"
					monthtree = MonthTransformer.new.apply(MonthParser.new.parse_with_debug(field[:field][1][:value].to_s))
					@entries[key][:month] = monthtree.to_s
				else
					texttree = TextTransformer.new(:unchanged).apply(TextParser.new.parse(field[:field][1][:value].to_s))
					@entries[key][field[:field][0][:name].to_s.downcase.to_sym] = texttree.to_s
				end
			end
		end
	end

	def html_of(key)
		if !@entries.has_key?(key) then
			return ""
		end

		outwhat = ""
		outwho = ""
		outwhere = []
		outnote = ""

		case @entries[key][:class]
		when "article"
			outwhat = @entries[key][:title]
			outwho = list_to_string(@entries[key][:author])
			outwhere.push("<em>" + @entries[key][:journal] + "</em>")
			if @entries[key].has_key?(:volume) then
				outwhere[-1] << ' ' + @entries[key][:volume]
				if @entries[key].has_key?(:number) then
					outwhere[-1] << '(' + @entries[key][:number] + ')'
				end
			elsif @entries[key].has_key?(:number) then
				outwhere[-1] << ' ' + @entries[key][:number]
			end
			if @entries[key].has_key?(:month) then
				outwhere.push(@lt.localisedmonth(@entries[key][:month]) + ' ' + @entries[key][:year])
			else
				outwhere.push(@entries[key][:year])
			end
			if @entries[key].has_key?(:pages) then
				outwhere.push(@lt.localise(:pp) + ' ' + @entries[key][:pages])
			end
			if @entries[key].has_key?(:note) then
				outnote = @entries[key][:note]
			end

		when "book"

		when "booklet"

		when "inbook"

		when "incollection"
			outwhat = @entries[key][:title]
			outwho = list_to_string(@entries[key][:author])
			outwhere.push(@lt.localise(:In) + ' ')
			if @entries[key].has_key?(:editor) then
				outwhere[-1] << list_to_string(@entries[key][:editor]) + ' (' + @lt.localise(:eds) + ')'
			end
			outwhere.push("<em>" + @entries[key][:booktitle] + "</em>")
			if @entries[key].has_key?(:type) then
				outwhere.push(@entries[key][:type])
			end
			if @entries[key].has_key?(:chapter) then
				outwhere.push(@lt.localise(:chapter) + ' ' + @entries[key][:chapter])
			end
			if @entries[key].has_key?(:series) then
				outwhere.push(@entries[key][:series])
				if @entries[key].has_key?(:volume) then
					outwhere[-1] << ' ' << @entries[key][:volume]
					if @entries[key].has_key?(:number) then
						outwhere[-1] << '(' + @entries[key][:number] + ')'
					end
				elsif @entries[key].has_key?(:number) then
					outwhere[-1] << ' ' + @entries[key][:number]
				end
			end
			outwhere.push(@entries[key][:publisher])
			if @entries[key].has_key?(:edition) then
				outwhere.push(@entries[key][:edition])
			end
			if @entries[key].has_key?(:address) then
				outwhere.push(@entries[key][:address])
			end
			if @entries[key].has_key?(:month) then
				outwhere.push(@lt.localisedmonth(@entries[key][:month]) + ' ' + @entries[key][:year])
			else
				outwhere.push(@entries[key][:year])
			end
			if @entries[key].has_key?(:pages) then
				outwhere.push(@lt.localise(:pp) + ' ' + @entries[key][:pages])
			end
			if @entries[key].has_key?(:note) then
				outnote = @entries[key][:note]
			end

		when "conference","inproceedings"
			outwhat = @entries[key][:title]
			outwho = list_to_string(@entries[key][:author])
			outwhere.push(@lt.localise(:In) + ' ')
			if @entries[key].has_key?(:editor) then
				outwhere[-1] << list_to_string(@entries[key][:editor]) + ' (' + @lt.localise(:eds) + ')'
			end
			outwhere.push("<em>" + @entries[key][:booktitle] + "</em>")
			if @entries[key].has_key?(:chapter) then
				outwhere.push(@lt.localise(:chapter) + ' ' + @entries[key][:chapter])
			end
			if @entries[key].has_key?(:series) then
				outwhere.push(@entries[key][:series])
				if @entries[key].has_key?(:volume) then
					outwhere[-1] << ' ' << @entries[key][:volume]
					if @entries[key].has_key?(:number) then
						outwhere[-1] << '(' + @entries[key][:number] + ')'
					end
				elsif @entries[key].has_key?(:number) then
					outwhere[-1] << ' ' + @entries[key][:number]
				end
			end
			if @entries[key].has_key?(:organization) then
				outwhere.push(@entries[key][:organization])
			end
			if @entries[key].has_key?(:publisher) then
				outwhere.push(@entries[key][:publisher])
			end
			if @entries[key].has_key?(:address) then
				outwhere.push(@entries[key][:address])
			end
			if @entries[key].has_key?(:month) then
				outwhere.push(@lt.localisedmonth(@entries[key][:month]) + ' ' + @entries[key][:year])
			else
				outwhere.push(@entries[key][:year])
			end
			if @entries[key].has_key?(:pages) then
				outwhere.push(@lt.localise(:pp) + ' ' + @entries[key][:pages])
			end
			if @entries[key].has_key?(:note) then
				outnote = @entries[key][:note]
			end

		when "manual"

		when "mastersthesis"

		when "misc"

		when "phdthesis"

		when "proceedings"

		when "techreport"

		when "unpublished"

		end

		if outwhat.length > 0 then
			outwhat = "<strong>" + outwhat + "</strong>. "
		end
		if outwho.length > 0 then
			outwho << ". "
		end
		if outwhere.length > 0 then
			outwhere = outwhere.join(', ') + '. '
		else
			outwhere = ""
		end
		if outnote.length > 0 then
			outnote << ". "
		end
		
		out = outwhat + outwho + outwhere + outnote
		out
	end
end

i = Imbiber.new
i.read("/Users/ken/Versioned/websites/work/publications.bib")
i.read("/Users/ken/Versioned/websites/work/others.bib")
# pp i.entries
pp i.html_of(:"12agile")

# text = File.read("/Users/ken/Versioned/websites/work/publications.bib")
# entries = DocumentParser.new.parse_with_debug(text)
# puts entries[:document][1]
