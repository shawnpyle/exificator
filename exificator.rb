#!/usr/bin/env ruby

require 'thor'
require 'fileutils'

require File.expand_path('lib/exiftool.rb', __dir__)
require File.expand_path('lib/prompt.rb', __dir__)

class Exificator < Thor
	PUNCTUATION_REGEX = /['"'`~;:{}\[\]()<>,\/\|!@#\$%^&*'.\?]/

	class_option :start, aliases: '-s', default: './', desc: "Starting directory to look for images."

	class_option :regex, aliases: '-r', default: '.*(jpe?g|png|tiff?)', desc: "The regular expression to match file names. Ensures .* starts the regex so it matches the path part of the file path."

	class_option :path, aliases: '-p', desc: "Path to a specific file. This will take presedence over start and regex options."

	class_option :depth, aliases: '-d', desc: "Depth of the directories to look in. By default this command is fully recursive."

	class_option :verbose, aliases: '-v', type: :boolean, desc: "Verbose output", default: true

	# class_option :dry_run, type: :boolean, desc: "Does not modify images"

	desc 'preview', 'Open the found images in Preview.app'
	def preview
		open(images.flatten.join("' '"))
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
			detail(image)
		end
	end

	option :show, type: :boolean, desc: 'Show the file'
	desc 'process', 'Add EXIF descriptions and rename file to match'
	def process
		images.each.with_index do |image,i|
			puts "#{i+1}/#{images.size}: Processing #{image}"
			exiftool = ExifTool.new(image)
			descriptions = exiftool.descriptions
			unless descriptions == ''
				puts "Current descriptions: "
				puts descriptions
			end
			open(image) if show
			new_description = Prompt.prompt("Enter new description:")
			next if new_description.empty?
			exiftool.descriptions = new_description

			renameWithDescription(image, new_description)
		end
	end

	option :format, desc: 'Extension of the format to convert to (e.g. jpg | tiff | png | gif). See sips command for more details', required: true
	desc 'convert', 'Convert images to a specific format'
	def convert
		if images.size == 0
			puts "No images found."
			return
		end

		unless Prompt.confirm?("Are you sure you want to convert #{images.size} images to #{options[:format]}? (y/n)")
			puts "Aborting convert!"
			return
		end

		images.each.with_index do |image,i|

			outfile = File.join(
				File.dirname(image),
				File.basename(image, '.*')+".#{format}"
			)
			puts "#{i+1}/#{images.size}: Converting #{image}"
			`sips -s format #{format} "#{image}" -s formatOptions 100 --out "#{outfile}"`
		end
	end

	option :prefix, type: :string, desc: 'Prefix to use. Defaults to last modified date in YYYYMMDDHHMMSS_ format.'
	desc 'rename', 'Renames in format <prefix>_<description>.<ext> if there is a description.'
	def rename
		if images.size == 0
			puts "No images found."
			return
		end

		unless Prompt.confirm?("Are you sure you want to rename #{images.size} images in the format of #{options[:prefix]||'YYYYMMDDHHMMSS'}_<description>? (y/n)")
			puts "Aborting rename!"
			return
		end

		images.each.with_index do |image,i|
			prefix = options[:prefix] || modified_at(image).strftime('%Y%m%d%H%M%S');
			ext = File.extname(image)
			dir = File.dirname(image)
			description = ExifTool.new(image).get('Description')
			descName = (description.empty? ? '' : '_'+description_to_name(description))
			newPath = File.join(dir,"#{prefix}#{descName}#{ext}")

			puts "#{i+1}/#{images.size}: Renaming #{image} to #{newPath}"
			FileUtils.move(image, newPath)
		end
	end

	private

	def description_to_name(description)
		description.strip.gsub(PUNCTUATION_REGEX,'').gsub(/\s+/,'_').gsub(/\_+/,'_')
	end

	def renameWithDescription(path, description)
		name = description_to_name(description)
		return if name.empty?

		ext = File.extname(path).downcase
		new_file = File.join(File.dirname(path),"#{name}#{ext}")
		while File.exists?(new_file)
			new_file = new_file.gsub(/(\.(\d+))?#{ext}/) { ".#{$2.to_i+1}#{ext}"}
		end
		FileUtils.move(path,new_file)
	end

	def start_dir
		@start_dir ||= File.expand_path(options[:start])
	end

	def regex
		@regex ||= lambda do
			rx = options[:regex]
			rx = ".*#{rx}" unless rx.start_with?('.*')
			return rx
		end.call
	end

	def path
		@path ||= options[:path]
	end

	def tag
		@tag ||= options[:tag]
	end

	def show
		@show ||= options[:show]
	end

	def format
		@format ||= options[:format]
	end

	def verbose?
		options.key?(:verbose)
	end

	# Returns array of image paths
	def images
		return @images if @images

		if path
			@images = (File.file?(path) ? [path] : [])
			return @images
		end

		@images = find
		puts "Found #{@images.size} images" if verbose?
		@images
	end

	def find
		command = %Q(find -E "#{start_dir}" -type f -iregex "#{regex}")
		command += " -maxdepth #{options[:depth]}" if options.key?(:depth)

		puts "Finding files with: #{command}" if verbose?
		`#{command}`.split("\n")
	end

	def detail(image)
		et = ExifTool.new(image)
		if options[:tag].strip.empty?
			descriptions = ExifTool.new(image).descriptions
			puts descriptions.empty? ? 'No descriptions were found' : descriptions
		else
			puts et.get(options[:tag], false)
		end
	end

	def open(image_list)
		`open -a Preview '#{image_list}'`
	end

	def modified_at(path)
		return File.mtime(path)
	end
end

begin
	Exificator.start(ARGV)
rescue SystemExit, Interrupt
	puts "\nGoodbye!"
end
