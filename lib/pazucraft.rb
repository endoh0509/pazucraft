#!/usr/bin/env ruby

#
# pazucraft.rb
#
# Copyright (c) 2015 Takehiko YOSHIDA
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#

require "pazucraft/version"
require 'rubygems'
require 'rmagick'


module Pazucraft
  def generate(input_path, output_path)
    equirectangular = Pazucraft::Equirectangular.new(input_path)
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
    frame.write(output_path)
  end
  module_function :generate

  class Equirectangular
    attr_reader :unit

    def initialize(file_name)
      @image = Magick::Image.read(file_name).first
      @unit = @image.columns / 8

      @offset = Array.new(5)
      @offset[0] = @unit * 0.0
      @offset[1] = @unit * (1.0 - 1.0 / Math::sqrt(2.0))
      @offset[2] = @unit * 0.5
      @offset[3] = @unit * (1.0 / Math::sqrt(2.0))
      @offset[4] = @unit * 1.0
    end

    def area(col, row)
      x = @unit * col
      width = @unit
      case row
      when 0
        y = 0
      when 1
        y = @unit * 1/2
      when 2
        y = @unit * 3/2
      when 3
        y = @unit * 5/2
      when 4
        y = @unit * 7/2
      else
        y = 0
      end

      case row
      when 0, 4
        height = @unit / 2
      when 1, 2, 3
        height = @unit
      else
        height = 0
      end
      [x, y, width, height]
    end

    def rectangular_piece(col, row)
      x, y, width, height = self.area(col, row)
      @image.crop(x, y, width, height)
    end

    def triangular_north_piece(col, row)
      img = self.rectangular_piece(col, row)
      frame = Magick::Image.new(@unit, @unit) {self.background_color = 'none'}
      frame.virtual_pixel_method = Magick::TransparentVirtualPixelMethod
      piece = frame.composite(img, 0, img.rows, Magick::OverCompositeOp)
      case col
        when 0, 2, 4, 6
          points = [@offset[0], @offset[2]]
          points += [@offset[2], @offset[2]]
          points += [@offset[4], @offset[2]]
          points += [@offset[2], @offset[2]]
          points += [@offset[0], @offset[4]]
          points += [@offset[1], @offset[4]]
          points += [@offset[4], @offset[4]]
          points += [@offset[3], @offset[4]]
        when 1, 5
          points = [@offset[0], @offset[2]]
          points += [@offset[2], @offset[2]]
          points += [@offset[4], @offset[2]]
          points += [@offset[2], @offset[2]]
          points += [@offset[0], @offset[4]]
          points += [@offset[3], @offset[4]]
          points += [@offset[4], @offset[4]]
          points += [@offset[4], @offset[3]-1]
        when 3, 7
          points = [@offset[0], @offset[2]]
          points += [@offset[2], @offset[2]]
          points += [@offset[4], @offset[2]]
          points += [@offset[2], @offset[2]]
          points += [@offset[0], @offset[4]]
          points += [@offset[0], @offset[3]-1]
          points += [@offset[4], @offset[4]]
          points += [@offset[1], @offset[4]]
        else
          return nil
      end

      distorted = piece.distort(Magick::BilinearDistortion, points)
      case col
        when 0, 1, 7
          rotated = distorted
        when 2
          rotated = distorted.rotate(-90)
        when 3, 4, 5
          rotated = distorted.rotate(180)
        when 6
          rotated = distorted.rotate(90)
        else
          rotated = nil
      end
      rotated
    end

    def triangular_south_piece(col, row)
      img = self.rectangular_piece(col, row)
      frame = Magick::Image.new(@unit, @unit) {self.background_color = 'none'}
      frame.virtual_pixel_method = Magick::TransparentVirtualPixelMethod
      piece = frame.composite(img, 0, 0, Magick::OverCompositeOp)
      case col
        when 0, 2, 4, 6
          points = [@offset[0], @offset[0]]
          points += [@offset[1], @offset[0]]
          points += [@offset[4], @offset[0]]
          points += [@offset[3], @offset[0]]
          points += [@offset[0], @offset[2]]
          points += [@offset[2], @offset[2]]
          points += [@offset[4], @offset[2]]
          points += [@offset[2], @offset[2]]
        when 1, 5
          points = [@offset[0], @offset[0]]
          points += [@offset[3], @offset[0]]
          points += [@offset[4], @offset[0]]
          points += [@offset[4], @offset[1]+1]
          points += [@offset[0], @offset[2]]
          points += [@offset[2], @offset[2]]
          points += [@offset[4], @offset[2]]
          points += [@offset[2], @offset[2]]
        when 3, 7
          points = [@offset[0], @offset[0]]
          points += [@offset[0], @offset[1]+1]
          points += [@offset[4], @offset[0]]
          points += [@offset[1], @offset[0]]
          points += [@offset[0], @offset[2]]
          points += [@offset[2], @offset[2]]
          points += [@offset[4], @offset[2]]
          points += [@offset[2], @offset[2]]
        else
          return nil
      end

      distorted = piece.distort(Magick::BilinearDistortion, points)
      case col
        when 0, 1, 7
          rotated = distorted
        when 2 then
          rotated = distorted.rotate(90)
        when 3, 4, 5
          rotated = distorted.rotate(180)
        when 6
          rotated = distorted.rotate(-90)
        else
          rotated = nil
      end
      rotated
    end

    def triangular_piece(col, row)
      case row
      when 0
        self.triangular_north_piece(col, row)
      when 4
        self.triangular_south_piece(col, row)
      else
        nil
      end
    end

    def trapezoid_piece(col, row)
      case row
      when 1
        points = [@offset[0], @offset[0]]
        points += [@offset[1], @offset[0]]
        points += [@offset[4], @offset[0]]
        points += [@offset[3], @offset[0]]
        points += [@offset[0], @offset[4]]
        points += [@offset[0], @offset[4]]
        points += [@offset[4], @offset[4]]
        points += [@offset[4], @offset[4]]
      when 3
        points = [@offset[0], @offset[0]]
        points += [@offset[0], @offset[0]]
        points += [@offset[4], @offset[0]]
        points += [@offset[4], @offset[0]]
        points += [@offset[0], @offset[4]]
        points += [@offset[1], @offset[4]]
        points += [@offset[4], @offset[4]]
        points += [@offset[3], @offset[4]]
      else
        return nil
      end

      piece = self.rectangular_piece(col, row)
      piece.virtual_pixel_method = Magick::TransparentVirtualPixelMethod
      piece.distort(Magick::BilinearDistortion, points)
    end

    def skewed_piece(col, row)
      case row
      when 0, 4
        if col == 0
          piece = self.pole(row)
        else
          piece = nil
        end
      when 1, 3
        piece = self.trapezoid_piece(col, row)
      when 2
        piece = self.rectangular_piece(col, row)
      else
        piece = nil
      end
      piece
    end

    def pole(row)
      frame = Magick::Image.new(@unit, @unit) { self.background_color = 'none' }
      for num in 0..7 do
        img = self.triangular_piece(num, row)
        frame = frame.composite(img, 0, 0, Magick::OverCompositeOp)
      end
      frame
    end
  end
end
