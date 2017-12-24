#!/usr/bin/env ruby

# This script changes the files found with the find to the modification date.

require 'date'
require 'fileutils'
require 'optparse'
require 'pp'

class Name2Date
	DEFAULTS = {start: Dir.pwd, depth: 1, regexp: '(IMG|VID)_.*'}

	def initialize
		@options = []
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

	def options
		return @options unless @options.empty?

		@options = DEFAULTS

		OptionParser.new do |opts|
			opts.banner = <<END
Usage: #{$0} [options]

This will search for files in the start directory and rename them based on the creation date. This is useful for
organizing photos by date.

Examples:
	#{$0} -r "(IMG|VID)_.*" # iPhone naming format

Options:
END

			opts.on("-r", "--regex=REGEXP", "REGEX of name, sent to `find` command, default is #{DEFAULTS[:regexp]}") do |regexp|
				@options[:regexp] = ".*/#{regexp}"
			end

			opts.on("-s", "--start=START-DIR", "Directory to start searching in, default is #{DEFAULTS[:start]}") do |start|
				@options[:start] = start.gsub(/\/$/,'')
			end

			opts.on("-d", "--depth=DEPTH", "Depth of subdirectories to search in, default is #{DEFAULTS[:depth]}") do |depth|
				@options[:depth] = depth.to_i
			end

			opts.on('-v', '--verbose', "Enbable verbose output") do |verbose|
				@options[:verbose] = verbose
			end
		end.parse!

		@options
	end

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
		FileUtils.mv(file, new_file)
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
