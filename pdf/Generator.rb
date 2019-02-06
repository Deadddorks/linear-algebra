
require 'prawn'
require 'KLib'

pdf = Prawn::Document.new

str = ''
500.times do |t|
	unless str.length == 0
		if t % 100 == 0
			str << "\n"
		else
			str << ' '
		end
	end
	str << t.to_s
end

stuff = proc do
	pdf.column_box([0, pdf.cursor], columns: 3, width: pdf.bounds.width) do
		pdf.text(str)
	end
	pdf.start_new_page
end

stuff.call

pdf.font('Courier-Bold')
stuff.call

pdf.page_count.times do |t|
	pdf.go_to_page(t + 1)
	pdf.stroke_bounds
end

proc2 = proc do
	logger = KLib::Logger.new(log_tolerance: :debug, display_level: false)
	
	logger.print("Hello there")
	logger.print("Hello there 2.0")
	logger.print("Ok\nthen...")
end

out, err, error = KLib::IoManipulation.snatch_io do
	proc2.call
end

until out.eof?
	pdf.text(out.readline.chomp.de_color)
end

pdf.render_file('my_pdf.pdf')


