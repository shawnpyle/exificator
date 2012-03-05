#!/usr/bin/env ruby

# INSTRUCTIONS
# Run this script from the command line in the folder with the images you want to 

# NOTICE
# This script requires the excellent exiftool 8.73 by Phil Harvey
# http://www.sno.phy.queensu.ca/~phil/exiftool/

require 'fileutils'

EXIFTOOL_URL = 'http://www.sno.phy.queensu.ca/~phil/exiftool/'
EXIFTOOL = '/usr/bin/exiftool'
#PREVIEW_TOOL = '/usr/bin/qlmanage -p'
PREVIEW_TOOL = 'open -a Preview'
CURRENT_DIR = Dir.pwd
EXTENSIONS = ['jpg','jpeg','png','tif','tiff']
PUNCTUATION_REGEX = /['"'`~;:{}\[\]()<>,\/\|!@#\$%^&*'.]/

# see http://www.macfreek.nl/mindmaster/Exiftool
META_DESCRIPTIONS = ['Description','ImageDescription','Caption-Abstract','Comment']

unless File.exists?(EXIFTOOL) 
  puts "exiftool does not exist on this system. Please download and install from #{EXIFTOOL_URL}."
  Kernel.exit
end

# Prompt the user for input.
def prompt(msg)
  msg += ' ' unless msg[-1..-1] == ' '
  STDOUT.write(msg)
  STDIN.gets.chomp
end

def confirm(msg) 
  prompt(msg)[0..0].downcase == 'y'
end

# Display the image (MAC OSX)
def preview(path)
  `#{PREVIEW_TOOL} '#{path}'`
  
  #paths = "\"#{paths.join('" "')}\""
  #`osascript -e 'tell application "Preview"' -e'activate' -e 'open POSIX file "/Users/USER_ID/Desktop/project.tiff"' -e ' end tell'  
end

# Return an array of images recursively.
def all_images(path)
  extensions = '{'+EXTENSIONS.join(',')+'}'
  paths = File.join(path,'**',"*.#{extensions}")
  Dir.glob(paths)
end

def get_meta(path,fields=[],only_value=true)
  args = []
  args << '-s3' if only_value
  for field in fields
    args << "-#{field}"
  end
  
  `#{EXIFTOOL} #{args.join(' ')} "#{path}"`.chomp
end

def set_meta(path,fields,value)
  args = []
  for field in fields
    args << "-#{field}=\"#{value}\""
  end
  `#{EXIFTOOL} #{args.join(' ')} -overwrite_original "#{path}"`
end

def get_descriptions(path)
  metas = get_meta(path,META_DESCRIPTIONS,false)  
  
  unless metas == ''
    puts "Current descriptions: "
    puts metas
    return true
  end
  
  false
end

def set_descriptions(path)
  description = prompt("Enter description:")  
  set_meta(path,META_DESCRIPTIONS,description) if description != ''
end

def rename_using_description(path)
  description = get_meta(path,['Description']).gsub(PUNCTUATION_REGEX,'').gsub(' ','_')
  return if description.empty?
  
  ext = File.extname(path)
  new_file = File.join(File.dirname(path),"#{description}#{ext}")
  while File.exists?(new_file)
    new_file = new_file.gsub(/(\.(\d+))?#{ext}/) { ".#{$2.to_i+1}#{ext}"}
    #puts "Trying to rename file to "+new_file
  end
  FileUtils.move(path,new_file)
end

if ARGV.size > 0
  images = ARGV.map {|p| File.expand_path(p) }
else #find images in current director
  images = all_images(CURRENT_DIR)
end

images = images.select{|i| File.exists?(i)}
if images.size == 0
  puts "No images found."
  Kernel.exit
end

puts "Found #{images.size} images. "
Kernel.exit if !confirm('Proceed?')

1.upto(images.size) do |i|
  image = images[i-1]
  
  puts "\n===== "+i.to_s+" of "+images.size.to_s+" ====="
  puts image
  
  #TODO: show all images in one preview window
  preview(image) #if confirm('Display image?')
  
  get_descriptions(image)
  set_descriptions(image)
  
  #if confirm("Rename using description?")
    rename_using_description(image)
  #end
end