
require 'klib'
Dir.chdir(File.dirname(__FILE__)) do
	require './../src/Matrix'
end

def grab_equations(file)
	KLib::ArgumentChecking.type_check(file, 'file', String)
	raise ArgumentError.new("Invalid path: #{file.inspect}'") unless File.exists?(file) && File.file?(file)
	
	eqs = []
	tmp = []
	
	File.read(file).split("\n").map { |str| str.strip }.each do |str|
		if str.length == 0 && tmp.any?
			eqs << tmp
			tmp = []
		else
			tmp << str
		end
	end
	eqs << tmp if tmp.any?
	
	eqs
end

puts("You specified (#{ARGV.length}) file#{ARGV.length == 1 ? '' : 's'}...")

systems = ARGV.map { |file| grab_equations(file) }.flatten(1)

systems.each do |system|
	puts
	puts("system:")
	system.each { |eq| puts("    #{eq}") }
	
	matrix = LinearAlgebra::Matrix.parse(system)
	puts
	puts("--- initial ---")
	puts(matrix)
	
	ref = matrix.to_ref
	puts
	puts("--- ref ---")
	puts(ref)
	
end
