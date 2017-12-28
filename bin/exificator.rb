#!/usr/bin/env ruby

require 'date'
require 'fileutils'
require 'pp'
%w(exiftool finder options prompt).each do |lib|
	require_relative "../lib/#{lib}"
end

class Exificator
	PUNCTUATION_REGEX = /['"'`~;:{}\[\]()<>,\/\|!@#\$%^&*'.\?]/
	attr_reader :options

	def initialize
		banner = <<END
		This script renames the files and updates the EXIF comment and description tags within the image to match.
END
		@options = Options.new(banner)
			.regexp('.*/.*(jpe?g|png|tiff?)')
			.start(Dir.pwd)
			.depth(1)
			.verbose
			.dry
			.help
			.options
	end

	# Display the image (MAC OSX)
	def preview(images)
		`open -a Preview '#{[images].flatten.join("' '")}'`
	end

	def rename_using_description(path, description)
		name = description.strip.gsub(PUNCTUATION_REGEX,'').gsub(/\s+/,'_').gsub(/\_+/,'_')
		return if name.empty?

		ext = File.extname(path).downcase
		new_file = File.join(File.dirname(path),"#{name}#{ext}")
		while File.exists?(new_file)
			new_file = new_file.gsub(/(\.(\d+))?#{ext}/) { ".#{$2.to_i+1}#{ext}"}
		end
		FileUtils.move(path,new_file)
	end

	def run
		images = Finder.new(options).files
		if images.size == 0
			puts "No images found."
			exi
		end

		puts "Found #{images.size} images. "
		if @options[:verbose]
			images.each{|i| puts i}
		end

		preview(images) if Prompt.confirm?('Preview images?')

		exit if !Prompt.confirm?('Proceed?')

		1.upto(images.size) do |i|
			image = images[i-1]

			if @options[:verbose]
				puts "\n===== "+i.to_s+" of "+images.size.to_s+" ====="
				puts image
			end

			exiftool = ExifTool.new(image)
			descriptions = exiftool.descriptions
			unless descriptions == ''
				puts "Current descriptions: "
				puts descriptions
			end

			new_description = Prompt.prompt("Enter new description:")
			exiftool.descriptions = new_description

			rename_using_description(image, new_description)
		end
	end
end

Exificator.new.run
