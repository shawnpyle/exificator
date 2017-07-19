#!/usr/bin/env ruby

# This script changes the files found with the find to the modification date. 

require 'date'
require 'fileutils'

if %w(-h --h -help --help help).include?(ARGV[0])
	puts "#{$0} [-h | START_DIR] [REGEXP]"
	exit 0
end

DIRECTORY=File.expand_path(ARGV[0])
REGEXP= ARGV[1] ? ARGV[1] : ".*\/(IMG|VID)_.*" #iPhone naming format
#REGEXP=".*\.(jpg|mp4)"
puts "Looking for files matching #{REGEXP} in #{DIRECTORY}"

files = `find -E "#{DIRECTORY}" -maxdepth 1 -type f -regex "#{REGEXP}"`.split("\n")
if files.empty?
	puts "No files were found in #{DIRECTORY}."
	exit 1
end

for file in files 
	#created_at = DateTime.strptime(`GetFileInfo -d "#{file}"`.strip,'%m/%d/%Y %H:%M:%S');
	modified_at = File.mtime(file)
	ext = File.extname(file)
	new_file = File.join(DIRECTORY,"#{modified_at.strftime("%Y%m%d%H%M%S")}#{ext}")
	i = 0
	while(File.exist?(new_file)) do
		new_file = File.join(DIRECTORY,"#{modified_at.strftime("%Y%m%d%H%M%S")}.#{i+=1}#{ext}")
	end
	puts "Moving #{file} => #{new_file}"
	FileUtils.mv(file, new_file)
	#break
end


=begin
rsync -av --progress --stats --ignore-existing --remove-source-files .* /Volumes/Public/Pictures/2015/
find . -type f -newermt 2015-01-01 ! -newermt 2016-01-01 -exec rsync -av --ignore-existing --remove-source-files {} /Volumes/Public/Pictures/2015/ \;
find . -type f -newermt 2015-01-01 ! -newermt 2016-01-01 -exec rsync -av --ignore-existing --remove-source-files {} /Volumes/Public/Pictures/2015/ \;
find . -type f -newermt 2015-01-01 ! -newermt 2016-01-01 | rsync -av --ignore-existing --remove-source-files --progress --stats /Volumes/Public/Pictures/2015/
find . -type f -newermt 2015-01-01 ! -newermt 2016-01-01 | rsync -av --ignore-existing --remove-source-files --itemize-changes /Volumes/Public/Pictures/2015/
find . -type f -newermt 2015-01-01 ! -newermt 2016-01-01 -exec rsync -av --ignore-existing --remove-source-files {} /Volumes/Public/Pictures/2015/ \;
find . -type f -newermt 2015-01-01 ! -newermt 2016-01-01 -exec rm  {} \;
=end
