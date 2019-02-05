
class Float
	alias :original_to_r :to_r
	def to_r(modified_behavior = true)
		return original_to_r unless modified_behavior
		split = self.to_s.split('.')
		Rational(split[0].to_i) + Rational(split[1].to_i, (10 ** (split[1].length)))
	end
end
