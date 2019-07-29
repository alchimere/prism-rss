# typed: true
require "rss"

class PrismRSSGenerator
  def initialize(extractor)
    @extractor = extractor
  end

  def generate
    @extractor.extract!
    RSS::Maker.make("atom") do |maker|
      puts @extractor.items.count
      maker.channel.author = @extractor.author
      maker.channel.updated = @extractor.date
      maker.channel.about = @extractor.url
      maker.channel.title = @extractor.title

      @extractor.items.each do |extracted_item|
        maker.items.new_item do |item|
          item.link = extracted_item.url
          item.title = extracted_item.title
          item.description = extracted_item.description
          item.updated = extracted_item.date
        end
      end
    end
  end
end
