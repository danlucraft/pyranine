require './extract'

require 'find'

Find.find(ARGV[0]) do |f|
  if File.basename(f) =~ /\.pdf$/
    p f
    if !File.directory?(f)
      notes = extract(f)
    end
  end
end
