class Finder

	# +params+ parameters to send to find.
	def initialize(params)
		@start = params[:start].gsub(/\/$/,'')
		@depth = params[:depth]
		@regexp = params[:regexp]
		@verbose = params[:verbose]
	end

	def files
		command = %Q(find -E "#{@start}" -maxdepth #{@depth} -type f -iregex "#{@regexp}" )
		puts "Finding files with: #{command}" if @verbose
		files = `#{command}`.split("\n")
	end
end
