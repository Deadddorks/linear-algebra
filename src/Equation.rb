
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
		
		def initialize(string)
			raise "No explicit conversion of #{string.class} to String" unless string.is_a?(String)
			orig = string
			raise "'#{string}' does not look like an equation" if /#{NUMBER}\s+#{VAR}/.match?(string)
			string = NORMALIZE.call(string)
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
			
			raise "You need at least 1 variable: '#{orig}'" if vars.empty?
			
			@vars = vars
			@const = const
		end
	
	end

end
