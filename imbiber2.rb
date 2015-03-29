#!/usr/bin/ruby

# Copyright (c) 2015 Ken Arroyo Ohori

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

require 'pp'
require 'parslet'

class DocumentParser < Parslet::Parser

	def stri(str)
		key_chars = str.split(//)
	    key_chars.collect! { |char| match["#{char.upcase}#{char.downcase}"] }.
		reduce(:>>)
	end

	root(:document)

	rule(:whitespace) { match['\s\n\r'].repeat(1) }
	rule(:whitespace?) { whitespace.maybe }
	rule(:bracketedtext) { str('{') >> (match['^{}'] | bracketedtext).repeat(1).maybe >> str('}') }
	rule(:parenthesisedtext) { str('(') >> (match['^){}'] | bracketedtext).repeat(1).maybe >> str(')') }
	rule(:quotedtext) { str('"') >> (match['^"{}']).repeat(1).maybe >> str('"') }
	rule(:newline) { str("\n") >> str("\r").maybe }

	rule(:document) { anyonething.repeat }
	rule(:anyonething) { nothing | something }
	rule(:nothing) { (str('@').absent? >> any).repeat(1) }
	rule(:something) { comment | string | preamble | entry.as(:entry) }

	rule(:comment) { str('@') >> whitespace? >> stri('comment') >> (newline.absent? >> any).repeat >> newline }

	rule(:string) { str('@') >> whitespace? >> stri('string') >> whitespace? >> (bracketedstring | parenthesisedstring) }
	rule(:bracketedstring) { str('{') >> whitespace? >> stringname >> whitespace? >> str('=') >> whitespace? >> stringvalue >> str('}') }
	rule(:parenthesisedstring) { str('(') >> whitespace? >> stringname >> whitespace? >> str('=') >> whitespace? >> stringvalue >> str(')') }
	rule(:stringname) { match['a-zA-Z'] >> match['a-zA-Z0-9'].repeat(1).maybe }
	rule(:stringvalue) { (quotedtext | stringname) >> whitespace? >> (str('#') >> whitespace? >> (quotedtext | stringname)).repeat(1).maybe }

	rule(:preamble) { str('@') >> whitespace? >> stri('preamble') >> whitespace? >> (bracketedtext | parenthesisedtext) }

	rule(:entry) { str('@') >> entryclass.as(:class) >> whitespace? >> (bracketedentrycontents | parenthesisedentrycontents) }
	rule(:entryclass) { match['^\s\n\r{},='].repeat(1) }
	rule(:bracketedentrycontents) { str('{') >> whitespace? >> entrykey.as(:key) >> whitespace? >> str(',') >> whitespace? >> entryfields.as(:fields) >> str(',').maybe >> whitespace? >> str('}') }
	rule(:parenthesisedentrycontents) { str('(') >> whitespace? >> entrykey.as(:key) >> whitespace? >> str(',') >> whitespace? >> entryfields.as(:fields) >> str(',').maybe >> whitespace? >> str(')') }
	rule(:entrykey) { match['^\s\n\r{},='].repeat(1) }
	rule(:entryfields) { entryfield.as(:field) >> whitespace? >> (str(',') >> whitespace? >> entryfield.as(:field) >> whitespace?).repeat(1).maybe }
	rule(:entryfield) { entryfieldname.as(:name) >> whitespace? >> str('=') >> whitespace? >> (bracketedvalue | quotedvalue | plainvalue.as(:value)).repeat }
	rule(:entryfieldname) { (match['^\s\n\r{},='] | bracketedtext).repeat(1) }

	rule(:bracketedvalue) { str('{') >> (match['^{}'] | bracketedtext).repeat.as(:value) >> str('}') }
	rule(:quotedvalue) { str('"') >> (match['^"{}'] | bracketedtext).repeat.as(:value) >> str('"') }
	rule(:plainvalue) { match['a-zA-Z0-9'].repeat(1) }

end

class Imbiber
	def read(path)
		text = File.read(path)
		entriestree = DocumentParser.new.parse(text)
	rescue Parslet::ParseFailed => failure
	    puts failure.cause.ascii_tree
	end
end

i = Imbiber.new
i.read("/Users/ken/Versioned/my-website/pubs/all.bib")