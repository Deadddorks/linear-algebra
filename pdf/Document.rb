
require 'prawn'
require 'KLib'
require_relative '../bin/solver'

module LinearAlgebra
	
	class Homework
		include Prawn::View
		
		def initialize(file, &block)
			raise ArgumentError.new("You need to supply a block to this method") unless block_given?
			@pdf = Prawn::Document.new
			@pdf.font("#{Prawn::DATADIR}/fonts/Courier-BoldRegular.ttf", size: 10)
			@first = true
			block.call(self)
			@pdf.number_pages("[<page>]", at: [0, 0], align: :center)
			@pdf.render_file(file)
		end
		
		def problem(name, &block)
			raise ArgumentError.new("You need to supply a block to this method") unless block_given?
			KLib::ArgumentChecking.type_check(name, 'name', String)
			
			if @first
				@first = false
			else
				@pdf.start_new_page
			end
			
			out, err = KLib::IoManipulation.snatch_io { block.call }
			
			@pdf.column_box([0, cursor], columns: 2, width: @pdf.bounds.width) do
				@pdf.text("Problem: #{name}", font: "#{Prawn::DATADIR}/fonts/Courier-BoldRegular.ttf", size: 15)
				@pdf.font("#{Prawn::DATADIR}/fonts/Courier-BoldRegular.ttf", size: 10)
				until out.eof?
					str = out.readline.chomp.de_color
					if str.length == 0
						@pdf.move_down(10)
					else
						@pdf.text(str)
					end
				end
			end
		end
		
		nil
	end
	
end

LinearAlgebra::Homework.new('MyHomework.pdf') do |hw|
	
	hw.problem("1.1") do
		Solve.solve(:debug, false, "a = 0")
	end
	
end
