
class Float
	alias :original_to_r :to_r
	def to_r(modified_behavior = true)
		return original_to_r unless modified_behavior
		split = self.to_s.split('.')
		Rational(split[0].to_i) + Rational(split[1].to_i, (10 ** (split[1].length)))
	end
end

class Rational
	
	alias :original_to_s :to_s
	def to_s(mode = :normal)
		KLib::ArgumentChecking.enum_check(mode, 'mode', :normal, :conv_rational, :conv_float)
		case mode
			when :normal
				original_to_s
			when :conv_rational
				self.denominator == 1 ? to_i.to_s : original_to_s
			when :conv_rational
				self.denominator == 1 ? to_i.to_s : to_f.to_s
			else
				raise "What is going on..."
		end
	end
	
	alias :original_inspect :inspect
	def inspect(mode = :normal)
		KLib::ArgumentChecking.enum_check(mode, 'mode', :normal, :conv_rational, :conv_float)
		case mode
			when :normal
				original_to_s
			when :conv_rational
				self.denominator == 1 ? to_i.inspect : original_inspect
			when :conv_rational
				self.denominator == 1 ? to_i.inspect : to_f.inspect
			else
				raise "What is going on..."
		end
	end
	
end
