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
	rule(:pseudoletter) { letter.as(:letter) | specialletter.as(:specialletter) }
	rule(:letter) { match['a-zA-Z'] }
	rule(:specialletter) { str('\\') >> modifier >> letter }
	rule(:modifier) { str("\'") | str("\"") | str("\^") }

end

class NameTransformer < Parslet::Transform
	sl = SpecialLetters.new

	rule(:letter => simple(:l)) { l.to_s }
	rule(:specialletter => simple(:l)) {
		sl.convert(l.to_s)
	}
	rule(:space => simple(:s)) { " " }
	# rule(:comma => simple(:c)) { "," }
	rule(:word => sequence(:w)) {
		w.join("")
	}
	
	# rule(:name => subtree(:s)) {
	# 	commas = 0
	# 	s.each do |token|
	# 		if token.is_a?(Hash) then
	# 			if token.has_key?(:comma) then
	# 				commas += 1
	# 			end
	# 		end
	# 	end
		
	# 	case commas
	# 	when 0
	# 		first = s[0..-2].join(" ")
	# 		last = s[-1]
	# 		{:first => first, :last => last}
	# 	when 1
	# 		first = []
	# 		last = []
	# 		commassofar = 0
	# 		s.each do |token|
	# 			if token.is_a?(Hash) then
	# 				if token.has_key?(:comma) then
	# 					commassofar += 1
	# 				end
	# 			elsif commassofar = 0
					
						
	# 			end

	# 		end
	# 	end
	# }
end

class Imbiber
	def initialize
		@entries = {}
	end

	def to_s
		return @entries.to_s
	end

	def read(path)
		text = File.read(path)
		entriestree = DocumentParser.new.parse(text)
		entriestree.each do |entrybranch|
			# Repeated key, skip
			if @entries.has_key?(entrybranch[:entry][:key]) then
				next
			end

			@entries[entrybranch[:entry][:key]] = {}
			@entries[entrybranch[:entry][:key]][:type] = entrybranch[:entry][:type]
			entrybranch[:entry][:fields].each do |field|
				# puts field[:field][0][:name].to_s.downcase
				case field[:field][0][:name].to_s.downcase
				when "author"
					# puts field[:field][1][:value].to_s
					authorstree = AuthorsParser.new.parse(field[:field][1][:value].to_s)
					authorstree.each do |author|
						nametree = NameTransformer.new.apply(NameParser.new.parse(author[:author].to_s))
						# puts nametree
					end
				when "editor"
					editorstree = AuthorsParser.new.parse(field[:field][1][:value].to_s)
					editorstree.each do |editor|
						nametree = NameTransformer.new.apply(NameParser.new.parse_with_debug(editor[:author].to_s))
						puts nametree
					end
				end
				# puts field[:field][1][:value].to_s
				# @entries[entrybranch[:entry][:key]][field[:field][0][:name].to_s.downcase] =  
			end

		# 	case entry[:entry][:type].to_s.downcase
		# 	when "article"
		# 		puts "article"

		# 	when "incollection"
		# 		puts "incollection"
		# 	when "inproceedings"
		# 		puts "inproceedings"
		# 	end
		end
	end
end

i = Imbiber.new
i.read("/Users/ken/Versioned/websites/work/publications.bib")
puts i.to_s

# text = File.read("/Users/ken/Versioned/websites/work/publications.bib")
# entries = DocumentParser.new.parse_with_debug(text)
# puts entries[:document][1]