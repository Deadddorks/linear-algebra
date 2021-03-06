
require 'KLib'
Dir.chdir(File.dirname(__FILE__)) do
	require './FloatToR'
	require './Equation'
end

module LinearAlgebra
	
	class Matrix
		
		attr_reader :num_rows, :state
		
		def initialize(variable_names, data)
			KLib::ArgumentChecking.check do |check|
				check.variable_names.type_check_each(String)
				check.data.type_check_each(Array, Row)
			end
			raise ArgumentError.new("You need at least 1 variable name") if variable_names.empty?
			raise ArgumentError.new("Array is empty") unless data.any?
			
			@names = variable_names
			
			@rows = data.map { |v| Row.new(v) }
			raise MatrixFormatError.new("Not rectangular") unless @rows.map { |v| v.num_vars }.uniq.length
			raise MatrixFormatError.new("num_vars must be > 0") unless @rows.first.num_vars
			
			@num_rows = @rows.length
			
			raise MatrixFormatError.new("Number of variables does not match variable names") unless @names.length == @rows[0].num_vars
			@names += ['=']
			@name_lengths = @names.map { |name| name.length }
			
			@state = :unknown
		end
		
		def dup
			mat = Matrix.new(@names[0..-2], @rows)
			mat.instance_variable_set(:@state, @state)
			mat
		end
		
		def [] (row)
			@rows[row]
		end
		
		def []= (idx, row)
			raise ArgumentError.new("No explicit conversion of #{row.class} to Row") unless row.is_a?(Row)
			@rows[idx] = row
		end
		
		def to_s(use_float = false)
			rows = @rows.map { |row| row.instance_variable_get(:@vars).map { |var| (var.denominator == 1 ? var.to_i : (use_float ? var.to_f : var)).to_s } }
			lengths = rows.map { |row| row.map { |var| var.length } }.transpose.map { |row| row.max }
			idx = -1
			lengths.map! { |len| idx += 1; @name_lengths[idx] > len ? @name_lengths[idx] : len }
			rows.map! { |row| idx = -1; row.map! { |var| idx += 1; var.rjust(lengths[idx]) } }
			
			idx = -1
			names = @names.map { |n| idx += 1; n.rjust(lengths[idx]) }
			
			str = "Matrix:"
			tmp = "[#{names[0..-2].join(' ')} | #{names[-1]}]"
			str << "\n" << tmp
			str << "\n" << ('-' * tmp.length)
			rows.each { |row| str << "\n[" << row[0..-2].join(' ') << " | " << row[-1] << "]" }
			str
		end
		
		def self.parse(equations)
			KLib::ArgumentChecking.type_check_each(equations, 'equations', Equation, String)
			if KLib::ArgumentChecking.type_check_each(equations, 'equations', String) {}
				equations = equations.map { |eq| Equation.new(eq) }
			else
				KLib::ArgumentChecking.type_check_each(equations, 'equations', Equation)
			end
			all_vars = []
			equations.each { |eq| all_vars |= eq.instance_variable_get(:@vars).keys }
			all_vars.sort!
			
			rows = equations.map do |eq|
				[*all_vars.map { |var| eq.instance_variable_get(:@vars)[var] }, eq.instance_variable_get(:@const)]
			end
			Matrix.new(all_vars, rows)
		end
		
		# Methods
		
		def to_ref!(logger = KLib::DeadObject.new)
			KLib::ArgumentChecking.type_check(logger, 'logger', KLib::Logger, KLib::DeadObject)
			return self unless %i{unknown}.include?(@state)
			
			logger.break
			logger.print("Converting to Row Echelon Form...")
			
			logger.indent + 1
			@num_rows.times do |idx|
				logger.info("starting row[#{idx + 1}]")
				logger.indent + 1
				
				left_most = [idx, @rows[idx].first_non_zero]
				(idx + 1).upto(@num_rows - 1) do |idx2|
					stats = [idx2, @rows[idx2].first_non_zero]
					left_most = stats if left_most[1].nil? || (!stats[1].nil? && stats[1] < left_most[1])
				end
				
				# Check for swaps
				if left_most[1].nil?
					logger.info("Only zero rows remain...")
					break
				elsif left_most[0] != idx
					logger.info("Swapping rows '#{idx + 1}' and '#{left_most[0] + 1}'")
					@rows[idx], @rows[left_most[0]] = @rows[left_most[0]], @rows[idx]
				end
				
				# The magic
				basic_col = left_most[1]
				current = @rows[idx]
				
				(idx + 1).upto(@num_rows - 1) do |idx2|
					if @rows[idx2][basic_col] == 0
						logger.info("row[#{idx2 + 1}] needs no additional work")
					else
						factor = @rows[idx2][basic_col] / current[basic_col]
						logger.info("row[#{idx2}] #{factor < 0 ? '+' : '-'}= #{factor.abs.inspect(:conv_rational)} * row[#{idx}]")
						@rows[idx2] -= current * factor
					end
				end
				logger.indent - 1
			end
			logger.indent- 1
			
			@state = :ref
			self
		end
		
		def to_ref(logger = KLib::DeadObject.new)
			self.dup.to_ref!(logger)
		end
		
		def to_rref!(logger = KLib::DeadObject.new)
			KLib::ArgumentChecking.type_check(logger, 'logger', KLib::Logger, KLib::DeadObject)
			return self unless %i{unknown ref}.include?(@state)
			self.to_ref!
			
			logger.break
			logger.print("Converting to Row Reduced Echelon Form...")
			
			logger.indent + 1
			(@num_rows - 1).downto(0) do |idx|
				basic_col = @rows[idx].first_non_zero
				if basic_col.nil?
					if @rows[idx][-1] != 0
						logger.error("System has no solution")
						@state = :no_sol
						logger.indent - 1
						return self
					else
						logger.info("Nothing to do with row[#{idx + 1}]")
					end
				else
					unless @rows[idx][basic_col] == 1
						factor = Rational(1) / @rows[idx][basic_col]
						logger.info("row[#{idx + 1}] *= #{factor.inspect(:conv_rational)}")
						@rows[idx] *= factor
					end
					current = @rows[idx]
					
					(idx - 1).downto(0) do |idx2|
						if @rows[idx2][basic_col] == 0
							logger.info("No need to reduce row[#{idx2 + 1}]")
						else
							factor = @rows[idx2][basic_col] / current[basic_col]
							logger.info("row[#{idx2 + 1}] #{factor < 0 ? '+' : '-'}= #{factor.abs.inspect(:conv_rational)} * row[#{idx + 1}]")
							@rows[idx2] -= current * factor
						end
					end
				end
			end
			logger.indent - 1
			
			@state = :rref
			self
		end
		
		def to_rref(logger = KLib::DeadObject.new)
			self.dup.to_rref!(logger)
		end
		
		def solve!(logger = KLib::DeadObject.new)
			KLib::ArgumentChecking.type_check(logger, 'logger', NilClass, KLib::Logger)
			if @state == :no_sol
				return nil
			else
				self.to_rref!
			end
			
			Solution.new(@names, @rows)
		end
		
		def solve(logger = KLib::DeadObject.new)
			self.dup.solve!(logger)
		end
		
		# Exceptions
		class MatrixFormatError < RuntimeError; end
		
		class Solution
			
			def initialize(names, rows)
				KLib::ArgumentChecking.type_check_each(names, 'names', String)
				KLib::ArgumentChecking.type_check_each(rows, 'rows', Row)
				@names = names
				@num_equations = rows.length
				@equations = rows.map { |row| Equation.new(:names => names, :row => row) }
				@basics = names[0..-2].map_to_h(:mode => :key) { nil }
				rows.length.times do |idx|
					row = rows[idx]
					eq = @equations[idx]
					first = row.first_non_zero
					unless first.nil?
						@basics[@names[first]] = eq
					end
				end
			end
			
			def equations
				str = ''
				@basics.each_pair do |var, eq|
					str << "\n" unless str.length == 0
					if eq.nil?
						str << "#{var} \u2208 \u211d"
					else
						str << eq.to_s(var)
					end
				end
				str
			end
			
			def set
				str = ''
				@basics.each_pair do |var, eq|
					str << "\n" unless str.length == 0
					if eq.nil?
						str << "#{var} \u2208 \u211d"
					else
						str << eq.to_s(var).split('=')[1].strip
					end
				end
				str
			end
		
		end
		
		class Row
			
			attr_reader :num_vars
			
			def initialize(data)
				KLib::ArgumentChecking.type_check(data, 'data', Array, Row)
				if data.is_a?(Row)
					@vars = Array.new(data.num_vars + 1) { |i| data[i] }
					@num_vars = data.num_vars
				elsif data.is_a?(Array)
					KLib::ArgumentChecking.type_check_each(data, 'data', Numeric)
					@vars = data.map { |v| v.to_r }
					@num_vars = data.length - 1
				else
					raise "What is going on"
				end
			end
			
			def dup
				Row.new(@vars)
			end
			
			def to_s
				vars = @vars.map { |v| v.to_s(:conv_rational) }
				"[#{vars[0..-2].join(' ')} | #{vars[-1]}]"
			end
			
			def [] (idx)
				@vars[idx]
			end
			
			def + (other_row)
				KLib::ArgumentChecking.type_check(other_row, 'other_row', Row)
				raise ArgumentError.new("Other row has different size") unless self.num_vars == other_row.num_vars
				Row.new(0.upto(@num_vars).map { |i| self[i] + other_row[i] })
			end
			def - (other_row)
				self + (other_row * -1)
			end
			
			def * (const)
				KLib::ArgumentChecking.type_check(const, 'const', Numeric)
				Row.new(@vars.map { |v| v * const })
			end
			
			def error_check
				first_non_zero.nil? && @vars[-1] != 0
			end
			
			def first_non_zero
				@num_vars.times { |idx| return idx unless @vars[idx] == 0 }
				nil
			end
		
		end
		
	end

end
