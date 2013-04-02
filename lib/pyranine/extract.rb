
module Pyranine
  # Extracts annotations from PDFs using pdf-reader
  class Extractor
    def initialize(path)
      @path = path
    end

    def annotations
      @annotations ||= begin
        as = []
        doc = PDF::Reader.new(@path)
        $objects = doc.objects
        doc.pages.each do |page|
          notes = notes_on_page(page)
          markups = markups_on_page(page)
          next unless notes.any? or markups.any?
          as << notes + markups
        end
        as.flatten
      end
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
      all_annots.select { |a| is_note?(a) }.map {|n| Note.new(page.number, n) }
    end

    def markups_on_page(page)
      all_annots = annots_on_page(page)
      markups = all_annots.select { |a| is_markup?(a) }.map {|a| Markup.new(page.number, a) }

      if markups.any?
        receiver = MarkupReceiver.new(markups)
        page.walk(receiver)
        coords = nil
        receiver.set_markup_texts
      end
      markups
    end
  end
end
