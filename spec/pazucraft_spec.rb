require 'spec_helper'

RSpec.describe Pazucraft do
  it 'does generate file using Pazucraft::Equirectangular' do
    p `rm spec/img/out.png`
    input_file = 'spec/img/test.jpg'
    output_file = 'spec/img/out.png'
    equirectangular = Pazucraft::Equirectangular.new(input_file)
    unit = equirectangular.unit
    frame = Magick::Image.new(unit * 8, unit * 5) { self.background_color = 'none' }
    for col in 0..7 do
      for row in 0..4 do
        piece = equirectangular.skewed_piece(col, row)
        if piece
          frame = frame.composite(piece, unit * col, unit * row, Magick::OverCompositeOp)
        end
      end
    end
    frame.write(output_file)
    expect(FileTest.exist?(output_file)).to eq(true)
  end

  it 'does generate file' do
    p `rm spec/img/out.png`
    input_file = 'spec/img/test.jpg'
    output_file = 'spec/img/out.png'
    Pazucraft::generate(input_file, output_file)
    expect(FileTest.exist?(output_file)).to eq(true)
  end
end
