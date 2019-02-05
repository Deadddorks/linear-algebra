
Dir.chdir(File.dirname(__FILE__)) do
	require './FloatToR'
end

module LinearAlgebra
	
	class Equation
		
		NORMALIZE = proc { |str| str.gsub(/\s+/, '').gsub(/(?<![\d*])#{VAR}/) { |match| "1#{match}" } }
		NUMBER = '-?\d+(\.\d+)?'
		VAR = '([A-Za-z]\d*)'
		SIGN = '[+-]'
		ENTRY = "(#{NUMBER}([*]??#{VAR}?))"
		SIDE = "#{ENTRY}(#{SIGN}#{ENTRY})*"
		EQUATION = /^#{SIDE}=#{SIDE}$/
		
		attr_accessor :vars, :const
		
		def initialize(input)
			KLib::ArgumentChecking.type_check(input, 'input', String, Hash)
			if input.is_a?(String)
				raise "'#{input}' does not look like an equation" if /#{NUMBER}\s+#{VAR}/.match?(input)
				string = NORMALIZE.call(input)
				raise "'#{string}' does not look like an equation" unless EQUATION.match?(string)
				left, right = string.gsub('*', '').gsub('--', '+').gsub('-', '+-').split('=').map { |s| s.gsub(/^[+]/, '').split('+') }
				right.map! { |r| "-#{r}".gsub('--', '') }
				all = [left, right].flatten
				
				vars = Hash.new { |h, k| h[k] = 0.0.to_r }
				const = (0.0).to_r
				all.each do |a|
					match = /(#{NUMBER})#{VAR}/.match(a)
					if match
						vars[match[3]] += match[1].to_f.to_r
					else
						const -= a.to_f.to_r
					end
				end
				
				raise "You need at least 1 variable: '#{input}'" if vars.empty?
				
				@vars = vars
				@const = const
			elsif input.is_a?(Hash)
				input = KLib::HashNormalizer.normalize(input) do |norm|
					norm.names.required.type_check_each(String)
					norm.row.required.type_check(Matrix::Row)
				end
				names = input[:names]
				row = input[:row]
				
				@vars = {}
				@const = row[row.num_vars]
				
				row.num_vars.times { |idx| @vars[names[idx]] = row[idx] }
			else
				raise "What is going on"
			end
		end
		
		def to_s(var = nil)
			KLib::ArgumentChecking.type_check(var, 'var', NilClass, String)
			vars = @vars.to_a.sort { |a, b| a[0] <=> b[0] }.to_h
			if var.nil?
				left = vars.transform_values { |v| v }.to_a
				right = []
			else
				raise "No such var '#{var}'" unless @vars.key?(var)
				left = [[var, vars[var]]]
				right = vars.select { |k, v| k != var }.transform_values { |v| -v }.to_a
			end
			conv = proc do |v|
				if v[1] == 0
					co = nil
				elsif v[1] == -1
					co = '-'
				elsif v[1] == 1
					co = ''
				else
					co = "#{v[1].inspect(:conv_rational)}"
				end
				co.nil? ? nil : "#{co}#{v[0]}"
			end
			left = left.map(&conv).select { |v| !v.nil? }
			right = right.map(&conv).select { |v| !v.nil? }
			
			return nil if left.empty?
			"#{left.join(' + ')} = #{@const.to_s(:conv_rational)}#{right.map { |v| " + #{v}" }.join('')}"
		end
	
	end

end
