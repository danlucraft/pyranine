require 'pdf-reader'
require './markup_receiver'

def extract(path)
  doc = PDF::Reader.new(path)
  $objects = doc.objects
  pages_to_annotations = {}
  doc.pages.each do |page|
    notes = notes_on_page(page)
    markups = markups_on_page(page)
    next unless notes.any? or markups.any?
    pages_to_annotations[page.number] = notes + markups
  end
  pages_to_annotations
end

def is_note?(object)
  object[:Type] == :Annot && [:Text, :FreeText].include?(object[:Subtype])
end

def is_markup?(object)
  object[:Type] == :Annot && [:Highlight, :Underline].include?(object[:Subtype])
end

def annots_on_page(page)
  references = (page.attributes[:Annots] || [])
  lookup_all(references).flatten
end

def lookup_all(refs)
  refs = *refs
  refs.map { |ref| lookup(ref) }
end

def lookup(ref)
  object = $objects[ref]
  return object unless object.is_a?(Array)
  lookup_all(object)
end

def notes_on_page(page)
  all_annots = annots_on_page(page)
  all_annots.select { |a| is_note?(a) }.map {|n| Note.new(n) }
end

def markups_on_page(page)
  all_annots = annots_on_page(page)
  markups = all_annots.select { |a| is_markup?(a) }.map {|a| Markup.new(a) }

  if markups.any?
    receiver = MarkupReceiver.new(markups)
    page.walk(receiver)
    coords = nil
    receiver.set_markup_texts
  end
  markups

end

class Annotation < Struct.new(:attributes)

  def created_at
    if s = attributes[:M]
      DateTime.strptime(s.split("Z").first, "D:%Y%m%d%H%M%S")
    end
  end

  def color
    rgb_to_hex(attributes[:C])
  end

  def rgb_to_hex(rgb)
    "#" + rgb.map {|i| (i*255).to_i.to_s(16).rjust(2, "0").upcase }.join
  end

  def contents
    attributes[:Contents].strip
  end
end

class Note < Annotation

  def inspect
    "<Note \"#{contents[0..20]}\">"
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
end
