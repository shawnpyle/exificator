#!/usr/bin/env ruby

require 'date'
require 'fileutils'
require 'pp'
require_relative '../lib/options'

class Name2Date
	attr_reader :options

	def initialize
		@options = []

		banner = <<END
Usage: #{$0} [options]

This will search for files in the start directory and rename them based on the creation date. This is useful for
organizing photos by date.

Examples:
#{$0} -r "(IMG|VID)_.*" # iPhone naming format
#{$0} -r ".*(gif|jpg|jpeg|png|tif|tiff)" # any image
#{$0} -r ".*(mov|mp4)" # any movie

Options:
END
		@options = Options.new(banner)
			.regex('.*/(IMG|VID)_.*')
			.start(Dir.pwd)
			.depth(1)
			.verbose
			.dry
			.help
			.options
	end

	def run
		f = files

		if f.size == 0
			puts "No files found"
			return
		end

		puts "Processing #{f.size} files..."
		for file in f
			rename(file)
		end

		puts "Done!"
	end

	private

	def files
		opts = options
		find_command = %Q(find -E "#{opts[:start]}" -maxdepth #{opts[:depth]} -type f -iregex "#{opts[:regexp]}" )
		puts "Finding files with: #{find_command}" if options[:verbose]
		files = `#{find_command}`.split("\n")
	end

	def new_name(file, version=nil)
		modified_at = File.mtime(file)
		ext = File.extname(file)
		dir = File.dirname(file)
		vers = version > 0 ? ".#{version}" : ''
		new_file = File.join(dir,"#{modified_at.strftime("%Y%m%d%H%M%S")}#{vers}#{ext}")
	end

	def rename(file)
		i = -1
		new_file = nil
		begin
			new_file = new_name(file, i+=1)
		end while(File.exist?(new_file))
		puts "Moving #{file} => #{new_file}" if options[:verbose]
		FileUtils.mv(file, new_file) unless options[:dry]
	end
end

Name2Date.new.run

=begin
rsync -av --progress --stats --ignore-existing --remove-source-files .* /Volumes/Public/Pictures/2015/
find . -type f -newermt 2015-01-01 ! -newermt 2016-01-01 -exec rsync -av --ignore-existing --remove-source-files {} /Volumes/Public/Pictures/2015/ \;
find . -type f -newermt 2015-01-01 ! -newermt 2016-01-01 -exec rsync -av --ignore-existing --remove-source-files {} /Volumes/Public/Pictures/2015/ \;
find . -type f -newermt 2015-01-01 ! -newermt 2016-01-01 | rsync -av --ignore-existing --remove-source-files --progress --stats /Volumes/Public/Pictures/2015/
find . -type f -newermt 2015-01-01 ! -newermt 2016-01-01 | rsync -av --ignore-existing --remove-source-files --itemize-changes /Volumes/Public/Pictures/2015/
find . -type f -newermt 2015-01-01 ! -newermt 2016-01-01 -exec rsync -av --ignore-existing --remove-source-files {} /Volumes/Public/Pictures/2015/ \;
find . -type f -newermt 2015-01-01 ! -newermt 2016-01-01 -exec rm  {} \;
=end
