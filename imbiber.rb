#!/usr/bin/ruby

require 'pp'
require 'parslet'
require 'parslet/convenience'

require_relative 'specialletters'

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

	rule(:entry) { str('@') >> entrytype.as(:type) >> whitespace? >> entrycontents }
	rule(:entrytype) { match['^\s\n\r{},='].repeat(1) }
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
	sl = SpecialLetters.new

	rule(:letter => simple(:l)) { l.to_s }
	rule(:specialletter => simple(:l)) { sl.convert(l.to_s) }
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
			{:first => first, :last => last}
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
			{:first => first.join(" "), :last => last.join(" ")}
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

class SentenceCaseTransformer < Parslet::Transform
	sl = SpecialLetters.new

	rule(:letter => simple(:l)) { l.to_s.downcase }
	rule(:specialletter => simple(:l)) { sl.convert(l.to_s.downcase) }
	rule(:letterpreservecase => simple(:l)) { l.to_s }
	rule(:specialletterpreservecase => simple(:l)) { sl.convert(l.to_s) }

	rule(:word => sequence(:w)) { w.join("") }

	rule(:text => sequence(:t)) {
		text = t.join(" ")
		text = text[0].upcase + text[1..-1]
		text
	}

end

class TextTransformer < Parslet::Transform
	sl = SpecialLetters.new

	rule(:letter => simple(:l)) { l.to_s }
	rule(:specialletter => simple(:l)) { sl.convert(l.to_s) }
	rule(:letterpreservecase => simple(:l)) { l.to_s }
	rule(:specialletterpreservecase => simple(:l)) { sl.convert(l.to_s) }

	rule(:word => sequence(:w)) { w.join("") }
	rule(:text => sequence(:t)) { t.join(" ") }

end

class Imbiber
	def initialize
		@entries = {}
	end

	def to_s
		return @entries.to_s
	end

	def entries
		@entries
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
			@entries[key][:type] = entrybranch[:entry][:type]
			entrybranch[:entry][:fields].each do |field|
				# puts field[:field][0][:name].to_s.downcase
				case field[:field][0][:name].to_s.downcase
				when "author"
					# puts field[:field][1][:value].to_s
					authorstree = AuthorsParser.new.parse(field[:field][1][:value].to_s)
					@entries[key][:author] = []
					authorstree.each do |author|
						nametree = NameTransformer.new.apply(NameParser.new.parse(author[:author].to_s))
						@entries[key][:author].push(nametree)
					end
				when "editor"
					editorstree = AuthorsParser.new.parse(field[:field][1][:value].to_s)
					@entries[key][:editor] = []
					editorstree.each do |editor|
						nametree = NameTransformer.new.apply(NameParser.new.parse_with_debug(editor[:author].to_s))
						@entries[key][:editor].push(nametree)
					end
				when "title"
					titletree = SentenceCaseTransformer.new.apply(TextParser.new.parse_with_debug(field[:field][1][:value].to_s))
					@entries[key][:title] = titletree.to_s
				else
					texttree = TextTransformer.new.apply(TextParser.new.parse_with_debug(field[:field][1][:value].to_s))
					@entries[key][field[:field][0][:name].to_s.downcase.to_sym] = texttree.to_s
				end
				# puts field[:field][1][:value].to_s
				# @entries[entrybranch[:entry][:key]][field[:field][0][:name].to_s.downcase] =  
			end
		end
	end
end

i = Imbiber.new
i.read("/Users/ken/Versioned/websites/work/publications.bib")
pp i.entries

# text = File.read("/Users/ken/Versioned/websites/work/publications.bib")
# entries = DocumentParser.new.parse_with_debug(text)
# puts entries[:document][1]