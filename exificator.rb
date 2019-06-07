#!/usr/bin/env ruby

require 'thor'
require 'fileutils'

require File.expand_path('lib/exiftool.rb', __dir__)
require File.expand_path('lib/prompt.rb', __dir__)

class Exificator < Thor
	PUNCTUATION_REGEX = /['"'`~;:{}\[\]()<>,\/\|!@#\$%^&*'.\?]/

	class_option :start, aliases: '-s', default: './', desc: "Starting directory to look for images."

	class_option :regex, aliases: '-r', default: '.*(jpe?g|png|tiff?)', desc: "The regular expression to match file names."

	class_option :path, aliases: '-p', desc: "Path to a specific file. This will take presedence over start and regex options."

	class_option :depth, aliases: '-d', desc: "Depth of the directories to look in. By default this command is fully recursive."

	class_option :verbose, aliases: '-v', type: :boolean, desc: "Verbose output", default: true

	class_option :dry_run, type: :boolean, desc: "Does not modify images"

	desc 'preview', 'Open the found images in Preview.app'
	def preview
		`open -a Preview '#{images.flatten.join("' '")}'`
	end

	desc 'list', 'Output a list of images found'
	def list
		puts images.sort.join("\n")
	end

	option :tag, aliases: '-t', default: ''
	desc 'details', 'Output EXIF data for image(s)'
	def details
		images.each do |image|
			puts "\nDetails for \"#{image}\"" if verbose?
			et = ExifTool.new(image)
			if options[:tag].strip.empty?
				descriptions = ExifTool.new(image).descriptions
				puts descriptions.empty? ? 'No descriptions were found' : descriptions
			else
				puts et.get(options[:tag], false)
			end
		end
	end

	# def rename
	# 	1.upto(images.size) do |i|
	# 		image = images[i-1]
	# 		puts "\n===== #{i.to_s} of #{images.size.to_s} =====" if verbose?
	# 		puts "Processing #{image}"
	# 		exiftool = ExifTool.new(image)
	# 		descriptions = exiftool.descriptions
	# 		unless descriptions == ''
	# 			puts "Current descriptions: "
	# 			puts descriptions
	# 		end
	#
	# 		new_description = Prompt.prompt("Enter new description:")
	# 		exiftool.descriptions = new_description
	#
	# 		rename_using_description(image, new_description)
	# 	end
	# end

	private

	# def using_description(path, description)
	# 	name = description.strip.gsub(PUNCTUATION_REGEX,'').gsub(/\s+/,'_').gsub(/\_+/,'_')
	# 	return if name.empty?
	#
	# 	ext = File.extname(path).downcase
	# 	new_file = File.join(File.dirname(path),"#{name}#{ext}")
	# 	while File.exists?(new_file)
	# 		new_file = new_file.gsub(/(\.(\d+))?#{ext}/) { ".#{$2.to_i+1}#{ext}"}
	# 	end
	# 	FileUtils.move(path,new_file)
	# end

	def start_dir
		@start_dir ||= File.expand_path(options[:start])
	end

	def regex
		@regex ||= options[:regex]
	end

	def path
		@path ||= options[:path]
	end

	def tag
		@tag ||= options[:tag]
	end

	def verbose?
		options.key?(:verbose)
	end

	# Returns array of image paths
	def images
		return [path] if path && File.file?(path)

		command = %Q(find -E "#{start_dir}" -type f -iregex "#{regex}")
		command += " -maxdepth #{options[:depth]}" if options.key?(:depth)

		puts "Finding files with: #{command}" if verbose?
		found = `#{command}`.split("\n")
		puts "Founnd #{found.size} images" if verbose?
		found
	end
end

Exificator.start(ARGV)
