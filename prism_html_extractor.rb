require 'nokogiri'
require 'open-uri'
require 'ostruct'
require 'yaml'

class PrismHtmlExtractor
  def initialize(filename)
    @filename = filename
    parse_config
  end

  def extract!
    page = Nokogiri::HTML(open(@url))

    extract_date(page)
    extract_title(page)
    extract_items(page)

    self
  end

  def author
    @author || "-"
  end

  def date
    (@date || DateTime.now).to_s
  end

  def url
    @url
  end

  def title
    t = @title || @url || @filename
    "#{t} (prism-rss)"
  end

  def items
    @items || []
  end

  private
  def extract_date(page)
    if @date_selector.nil? || @date_selector.empty?
      @date = DateTime.now
    else
      date_str = page.css(@date_selector).text

      if @date_extractor
        date_str = date_str.match(Regexp.new(@date_extractor))[1]
      end

      @date = date_str
    end
  end

  def extract_title(page)
    @title = page.css(@title_selector).text
  end

  def extract_items(page)
    @items = []
    page.css(@item_selector).each do |item|
      d = item.css(@item_date_selector).text
      if @item_date_extractor
        d = d.match(Regexp.new(@item_date_extractor))[1] rescue d
      end
      d = DateTime.parse(d).to_s rescue DateTime.now.to_s

      link = first_node(item.css(@item_link_selector))['href'] || '/'
      link = URI.join(@url, link).to_s if not link.start_with?('http')

      @items << OpenStruct.new(
        url: link,
        title: item.css(@item_title_selector).text || "Unknown title",
        date: d
      )
    end
    @items
  end

  def parse_config
    File.open(@filename, 'r') do |f|
      yaml = YAML.load(f.read)
      @url = yaml['url']
      @author = yaml['author']
      @date_selector = yaml['selectors']['date']
      @date_extractor = yaml['extractors']['date']
      @title_selector = yaml['selectors']['title'] || "head title"

      @item_selector = yaml['selectors']['item']
      @item_link_selector = yaml['selectors']['item_link']
      @item_title_selector = yaml['selectors']['item_title']

      @item_date_selector = yaml['selectors']['item_date']
      @item_date_extractor = yaml['extractors']['item_date']
    end
  end

  def first_node(node)
    case node
    when Nokogiri::XML::NodeSet then node[0]
    else node
    end
  end
end
