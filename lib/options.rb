require 'optparse'

class Options
	def initialize(banner)
		@parser = OptionParser.new
		@parser.banner = banner
		@options = {}
		@parsed = false
	end

	def options
		return @options if @parsed
		@parser.parse!
		@parsed = true
		check_for_help
		check_for_dry_run
		@options
	end

	def regexp(default = nil)
		add_option(:regexp, default, '-r', '--regexp=REGEXP', 'Regular expression of name, sent to `find` command')
	end

	def start(default = nil)
		add_option(:start, default, '-s', '--start=START/DIR', 'Directory to start searching in')
	end

	def depth(default = nil)
		add_option(:depth, default, '-d', '--depth=DEPTH', 'Depth of subdirectories to search in')
	end

	def verbose(default = false)
		add_option(:verbose, default, '-v', '--verbose', 'Enable verbose output')
	end

	def dry(default = false)
		add_option(:dry, default, '--dry', 'Dry running the script but not modifying any files. Some output might be incorrect if dependent on files being changed. This is helpful when tweaking the other parameters before doing a "wet" run.')
	end

	def help
		add_option(:help, false, '-h', '--help', 'Prints this help')
	end

	private

	def add_option(name, default, *parser_options)
		parser_options[-1] += ", default is #{default}" if default
		@options[name] = default
		@parser.on(*parser_options) do |x|
			@options[name] = x
		end
		self
	end

	def check_for_help
		return unless @options[:help] || ARGV.empty?
		puts @parser
		exit
	end

	def check_for_dry_run
		return unless @options[:dry]
		puts "#{'#'*10} DRY RUN! NO MODIFICATIONS WILL BE MADE #{'#'*10}"
	end
end
