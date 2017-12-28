require_relative './prompt'

# A simple wrapper for the exiftool utility.
class ExifTool
	BINARY = `which exiftool`.chomp
	URL = 'http://www.sno.phy.queensu.ca/~phil/exiftool/'
	# see http://www.macfreek.nl/mindmaster/Exiftool
	META_DESCRIPTIONS = ['Description','ImageDescription','Caption-Abstract','Comment']

	attr_reader :path

	def initialize(path)
		@path = path

		unless File.exist?(path)
			puts "File #{path} doesn't exist! Please correct before sending to #{__class__}"
		end

		unless exist?
			puts "exiftool does not exist on this system. Please download and install. See #{URL}"
			exit
		end
	end

	def exist?
		return !BINARY.empty?
	end

	def version
		`exiftool -ver`.chomp
	end

	def descriptions
		get(META_DESCRIPTIONS,false)
	end

	def descriptions=(description)
		pp description
		set(META_DESCRIPTIONS,description) if description.strip != ''
	end

	private

	def get(fields=[],only_value=true)
		args = []
		args << '-s3' if only_value
		[fields].flatten.each do |field|
			args << "-#{field}"
		end
		`#{BINARY} #{args.join(' ')} "#{path}"`.chomp
	end

	def set(fields,value)
		args = ['-overwrite_original']
		[fields].flatten.each do |field|
			args << "-#{field}=\"#{value}\""
		end
		pp "#{BINARY} #{args.join(' ')} \"#{path}\""
		`#{BINARY} #{args.join(' ')} "#{path}"`
	end
end
