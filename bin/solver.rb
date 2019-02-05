
require 'KLib'
Dir.chdir(File.dirname(__FILE__)) do
	require './../src/Matrix'
end

module Solve
	extend KLib::CliMod
	
	method_spec(:solve) do |met|
		met.symbol(:log_level).enum_check(KLib::LogLevelManager::DEFAULT_LOG_LEVEL_MANAGER.valid_levels).default_value(:important)
		met.boolean(:display_log_level).boolean_data(:mode => :_dont).default_value(false)
	end
	
	def self.solve(log_level, display_log_level, *equations)
		logger = KLib::Logger.new(:log_tolerance => log_level, :display_level => display_log_level)
		
		if equations.empty?
			logger.fatal("You need at least 1 equation")
			exit(1)
		end
		
		parsed_equations = []
		invalid_equations = []
		equations.each do |eq|
		  begin
			  parsed_equations << LinearAlgebra::Equation.new(eq)
		  rescue
			  invalid_equations << eq
		  end
		end
		if invalid_equations.any?
			logger.fatal("Found invalid equations...")
			logger.indent + 1
			invalid_equations.each{ |eq| logger.fatal("~ #{eq.inspect}") }
			logger.indent - 1
		end
		
		logger.print("Equations:")
		logger.indent + 1
		parsed_equations.each { |eq| logger.print("~ #{eq.to_s.inspect}") }
		logger.indent - 1
		logger.break
		
		begin
			matrix = LinearAlgebra::Matrix.parse(equations)
			logger.important("Original #{matrix}")
			
			ref_matrix = matrix.to_ref(logger)
			logger.important("REF #{ref_matrix}")
			
			rref_matrix = ref_matrix.to_rref(logger)
			logger.important("RREF #{rref_matrix}")
			
			solution = rref_matrix.solve(logger)
			logger.important("Solution:\n#{solution.equations}")
		rescue => e
			logger.fatal(e.inspect)
			e.backtrace.each { |b| logger.debug(b) }
			exit(1)
		end
		
	end
	
end

if File.expand_path($0) == File.expand_path(__FILE__)
	Solve.parse
end
