class Prompt
	# Prompt the user and return input
	def self.prompt(msg)
		msg += ' ' unless msg[-1..-1] == ' '
		STDOUT.write(msg)
		STDIN.gets.chomp
	end

	# Confirm with the user
	def self.confirm?(msg)
		prompt(msg)[0..0].downcase == 'y'
	end
end
