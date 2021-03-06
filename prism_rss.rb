# typed: true
require './prism_html_extractor'
require './prism_rss_generator'

class PrismRSS
  def run(param_filename = nil)
    if param_filename
      rssify(param_filename)
    else
      files.each do |filename|
        rssify(filename)
      end
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
    puts("#{e.class.name}: #{e.message}")
    puts(e.backtrace.join("\n"))
  end

  def files
    Dir['./sources/*.yml']
  end

  def out_path(filename)
    "rss/#{filename.rpartition('/').last.rpartition('.').first}.rss"
  end
end
