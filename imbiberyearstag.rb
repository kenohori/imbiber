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

require 'liquid'

require_relative 'imbiber'

class ImbiberYearsTag < Liquid::Tag
	def initialize(tag_name, command, tokens)
		super
		@arguments = {}
		command.split.each do |part|
			if part.include?(':') then
				keyval = part.split(":")
				@arguments[keyval[0].to_sym] = keyval[1]
			else
				@file = part
			end
		end
		@imbiber = Imbiber.new(@arguments)
	end

	def render(context)

		# Convert relative paths
		if @file[0] != "." && @file[0] != "/" then
			@file = context.registers[:site].config["source"] + "/" + @file
		end

		# Read file
		@imbiber.read(@file)

		# Call imbiber
		if @arguments.has_key?(:idswithprefix) then
			@idswithprefix = @arguments[:idswithprefix]
		else
			@idswithprefix = false
		end
		if @arguments.has_key?(:format) then
			@format = @arguments[:format].to_sym
		else
			@format = :list
		end
		@imbiber.yearnav(@idswithprefix, @format)
	end
end

Liquid::Template.register_tag('imbiber_years', ImbiberYearsTag)

# template = Liquid::Template.parse('{% imbiber_years publications.bib idswithprefix:pr %}')
# puts template.render
