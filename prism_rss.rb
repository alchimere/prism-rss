require './prism_html_extractor'
require './prism_rss_generator'

class PrismRSS
  def run
    files.each do |filename|
      rssify(filename)
    end
  end

  def rssify(filename)
    extractor = PrismHtmlExtractor.new(filename)
    rss = PrismRSSGenerator.new(extractor).generate
    out = out_path(filename)
    File.open(out, "w+") do |f|
      f.truncate(0)
      f.write(rss.to_s)
    end
  rescue => e
    puts("Error: #{e.message}")
    puts(*e.backtrace)
  end

  def files
    Dir['./sources/*.yml']
  end

  def out_path(filename)
    "rss/#{filename.rpartition('/').last.rpartition('.').first}.rss"
  end
end
