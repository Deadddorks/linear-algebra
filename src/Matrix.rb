
class Matrix

	attr_reader :num_rows, :state

	def initialize(data)
		raise ArgumentError.new("No explicit conversion of (data) #{data.class} to Array") unless data.is_a?(Array)
		raise ArgumentError.new("Array is empty") unless data.any?
		
		@rows = data.map { |v| Row.new(v) }
		raise MatrixFormatError.new("Not rectangular") unless @rows.map { |v| v.num_vars }.uniq.length
		raise MatrixFormatError.new("num_vars must be > 0") unless @rows.first.num_vars
		
		@num_rows = @rows.length
		
		@state = :unknown
	end
	
	def dup
		Matrix.new(@rows)
	end
	
	def [] (row)
		@rows[row]
	end
	
	def []= (idx, row)
		raise ArgumentError.new("No explicit conversion of #{row.class} to Row") unless row.is_a?(Row)
		@rows[idx] = row
	end
	
	def to_s
		str = "#<Matrix: @num_rows=#{@num_rows}, @rows="
		@rows.each { |r| str << "\n    " << r.to_s }
		str << "\n>"
		str
	end
	
	class MatrixFormatError < RuntimeError; end
	
	class Row
		
		attr_reader :num_vars
		
		def initialize(data)
			if data.is_a?(Row)
				@vars = Array.new(data.num_vars + 1) { |i| data[i] }
				@num_vars = data.num_vars
			elsif data.is_a?(Array)
				data.each { |d| raise ArgumentError.new("No explicit conversion of #{data.class} to Numeric") unless d.is_a?(Numeric) }
				@vars = data.map { |v| v.to_r }
				@num_vars = data.length - 1
			else
				raise ArgumentError.new("No explicit conversion of #{data.class} to one of [Array, Row]") unless (data.is_a?(Array) || data.is_a?(Row))
			end
		end
		
		def dup
			Row.new(@vars)
		end
		
		def to_s
			vars = @vars.map { |v| v.denominator == 1 ? v.to_i.to_s : v.to_f.to_s }
			"[#{vars[0..-2].join(' ')} | #{vars[-1]}]"
		end
		
		def [] (idx)
			@vars[idx]
		end
		
		def + (other_row)
			raise ArgumentError.new("No explicit conversion of #{other_row.class} to Row") unless other_row.is_a?(Row)
			raise ArgumentError.new("Other row has different size") unless self.num_vars == other_row.num_vars
			0.upto(@num_vars).map { |i| self[i] + other_row[i] }
		end
		
		def * (const)
			raise ArgumentError.new("No explicit conversion of #{const.class} to Numeric") unless const.is_a?(Numeric)
			Row.new(@vars.map { |v| v * const })
		end
		
	end
	
	# Methods
	
	def to_row_echelon_form
		matrix = self.dup
		matrix.num_rows
		
		matrix
	end

end

matrix = Matrix.new([
	[1,2,3],
	[4,5,6],
	[7,8,9]
])

matrix2 = matrix.dup
puts matrix
puts matrix2

matrix[0] *= 2
puts matrix
puts matrix2

matrix[0], matrix[1] = matrix[1], matrix[0]
puts matrix
puts matrix2
