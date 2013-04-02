require './extract'

require 'find'
require 'erb'

class Viewer
  attr_reader :docs

  def initialize
    @docs = {}
  end

  def to_html
    renderer = ERB.new(File.read("./index.html.erb"))
    renderer.result(binding)
  end

  class Doc
    attr_reader :pages

    def initialize
      @pages = {}
    end
  end

  class Page
    attr_reader :annotations

    def initialize
      @annotations = []
    end
  end
end

viewer = Viewer.new

Find.find(ARGV[0]) do |f|
  if File.basename(f) =~ /\.pdf$/
    if !File.directory?(f)
      annotations = extract(f)
      if annotations.any?
        doc = Viewer::Doc.new
        annotations.each do |i, as|
          page = Viewer::Page.new
          as.each {|a| page.annotations << a }
          doc.pages[i] = page
        end
        viewer.docs[f] = doc
      end
    end
  end
end

puts viewer.to_html
