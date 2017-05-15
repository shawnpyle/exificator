#!/usr/bin/env ruby

# This script changes the files found with the the FILE_REGEXP to the modification date. 

require 'date'
require 'fileutils'

DIRECTORY=File.expand_path(ARGV[0])
FILE_REGEXP=/IMG_\d+/ #images from iPhone Camera Roll

files = `find "#{DIRECTORY}"`.split("\n")
files.select!{|f| File.basename(f) =~ FILE_REGEXP }

if files.empty?
	puts "No files were found in #{DIRECTORY}."
	exit 1
end

for file in files 
	#created_at = DateTime.strptime(`GetFileInfo -d "#{file}"`.strip,'%m/%d/%Y %H:%M:%S');
	modified_at = File.mtime(file)
	ext = File.extname(file)
	new_file = File.join(DIRECTORY,"#{modified_at.strftime("%Y%m%d%H%M%S")}#{ext}")
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
