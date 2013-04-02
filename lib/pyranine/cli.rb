module Pyranine
  class CLI < Struct.new(:args)
    def target_dir
      ARGV[0]
    end

    def generate
      viewer = Viewer.new(target_dir)

      Find.find(target_dir) do |f|
        if File.basename(f) =~ /\.pdf$/
          if !File.directory?(f)
            extractor = Extractor.new(f)
            annotations = extractor.annotations
            if annotations.any?
              doc = Viewer::Doc.new(f)
              annotations.each do |a|
                page = (doc.pages[a.page] ||= Viewer::Page.new(a.page))
                page.annotations << a
              end
              viewer.docs << doc
            end
          end
        end
      end

      puts viewer.to_html
    end
  end
end
