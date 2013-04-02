module Pyranine
  class Viewer
    attr_reader :docs, :target_dir

    def initialize(target_dir)
      @target_dir = target_dir
      @docs = []
    end

    def to_html
      renderer = ERB.new(File.read(File.expand_path("../../../templates/index.html.erb", __FILE__)))
      renderer.result(binding)
    end

    class Doc
      attr_reader :pages, :filename

      def initialize(filename)
        @pages = {}
        @filename = filename
      end
    end

    class Page
      attr_reader :annotations, :number

      def initialize(number)
        @number = number
        @annotations = []
      end
    end
  end
end
