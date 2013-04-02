

module Pyranine
  class Annotation < Struct.new(:page, :attributes)

    def created_at
      if s = attributes[:M]
        DateTime.strptime(s.split("Z").first, "D:%Y%m%d%H%M%S")
      end
    end

    def color
      rgb_to_hex(attributes[:C])
    end

    def rgb_to_hex(rgb)
      if rgb
        "#" + rgb.map {|i| (i*255).to_i.to_s(16).rjust(2, "0").upcase }.join
      else
        "#000000"
      end
    end

    def contents
      c = attributes[:Contents]
      c ? c.strip : c
    end
  end

  class Note < Annotation

    def inspect
      "<Note \"#{contents[0..20]}\">"
    end

    def empty?
      contents == ""
    end

    def to_html
      "<span class=note style=\"color: #{color};\">#{ contents }</span>"
    end
  end

  class Markup < Annotation
    attr_accessor :text

    class Rectangle
      attr_reader :quad_points

      def initialize(points)
        @quad_points = points.sort
      end

      def bottom_left
        quad_points[0]
      end

      def top_left
        quad_points[1]
      end

      def bottom_right
        quad_points[2]
      end

      def top_right
        quad_points[3]
      end

      def contains?(coords)
        x, y = *coords
        x >= bottom_left.first && x <= top_right.first &&
          y >= bottom_left.last && y <= top_right.last
      end

      def within?(bottom, top)
        bottom_left[1] >= bottom && bottom_left[1] <= top
      end

    end

    def inspect
      "<Markup \"#{(text || "")[0..20]}...\">"
    end

    def contains?(x, y)
      rectangles.any? {|r| r.contains?([x, y]) }
    end

    def within?(bottom, top)
      rectangles.any? {|r| r.within?(bottom, top) }
    end

    def rectangles
      attributes[:QuadPoints].each_slice(8).to_a.map do |ps|
        Rectangle.new(ps.each_slice(2).to_a)
      end
    end

    def empty?
      contents == "" and [nil, ""].include?(text) 
    end

    def to_html
      "<span class=markup style=\"color: #{color};\">#{ text }</span>"
    end
  end

end
