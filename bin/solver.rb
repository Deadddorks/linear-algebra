
require 'KLib'
Dir.chdir(File.dirname(__FILE__)) do
	require './../src/Matrix'
end

$la_log = KLib::Logger.new(:log_tolerance => :debug)

module Solve
	extend KLib::CliMod
	
	method_spec(:solve) do |met|
		met.boolean(:ref).default_value(false)
		met.boolean(:rref).default_value(false)
		met.boolean(:show_steps).default_value(false).boolean_data(:mode => :_dont)
		met.boolean(:debug_info).default_value(false)
	end
	
	def self.solve(ref, rref, show_steps, debug_info, *equations)
		if debug_info
			# Set log levels
		else
			# Set log levels
		end
		if equations.empty?
			$la_log.fatal("You need at least 1 equation")
			exit(1)
		end
		
		$la_log.print("Equations:")
		$la_log.indent + 1
		equations.each { |eq| $la_log.print("~ #{eq.inspect}") }
		$la_log.indent - 1
		$la_log.break
		
		begin
			matrix = LinearAlgebra::Matrix.parse(equations)
			ref_matrix = matrix.to_ref
			rref_matrix = ref_matrix.to_rref
		rescue => e
			$la_log.fatal(e.inspect)
			e.backtrace.each { |b| $la_log.debug(b) }
			exit(1)
		end
		
		$la_log.print("Original #{matrix.to_s}")
		$la_log.print("REF #{ref_matrix.to_s}")
		$la_log.print("RREF #{rref_matrix.to_s}")
	end
	
end

if File.expand_path($0) == File.expand_path(__FILE__)
	Solve.parse
end
