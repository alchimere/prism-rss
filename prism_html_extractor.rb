require 'nokogiri'
require 'open-uri'
require 'ostruct'
require 'watir'
require 'webdrivers'
require 'yaml'

class PrismHtmlExtractor
  def initialize(filename)
    @filename = filename
    parse_config
  end

  def extract!
    puts "Extracting #{url}"
    static_extract! if not @browser
    watir_extract! if items.empty?
    self
  end

  def author
    @author || "-"
  end

  def date
    case @date
    when DateTime then @date.to_s
    when /^[0-9]+$/ then Time.at(@date.to_i).to_datetime.to_s
    else
      (@date || DateTime.now).to_s
    end.tap { |d| puts d }
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
  def static_extract!
    extract_from_html(open(@url))
  end

  def watir_extract!
    browser = Watir::Browser.new :firefox
    puts "[WATIR] go to #{url}"
    browser.goto url
    # Wait for the three selectors
    [@item_selector].each do |selector|
      next if selector.nil? || selector.empty?
      puts "[WATIR] Wait for #{selector}"
      browser.element(css: selector).wait_until(&:exists?)
      puts "[WATIR] Wait done"
    end
    html = browser.html
    browser.close
    puts "[WATIR] End of browsing"
    extract_from_html(html)
  rescue => e
    puts "[WATIR] Error: #{e.message}"
    browser.close
  end

  def extract_from_html(html_content)
    page = Nokogiri::HTML(html_content)

    extract_date(page)
    extract_title(page)
    extract_items(page)
  end

  def extract_date(page)
    if @date_selector.nil? || @date_selector.empty?
      @date = DateTime.now
    else
      date_str = page.css(@date_selector).text.strip

      if @date_extractor
        date_str = date_str.match(Regexp.new(@date_extractor))[1].strip
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
      d = nil
      if @item_date_selector && !@item_date_selector.empty?
        d = item.css(@item_date_selector).text
        if @item_date_extractor
          d = d.match(Regexp.new(@item_date_extractor))[1] rescue d
        end
      else
        d = @date || extract_date(page)
      end
      d = DateTime.parse(d).to_s rescue DateTime.now.to_s

      item_link = if @item_link_selector && !@item_link_selector.empty?
                    item.css(@item_link_selector)
                  else
                    item
                  end
      link = first_node(item_link)['href'] || '/'
      link = URI.join(@url, link).to_s if not link.start_with?('http')

      title_str = if @item_title_selector.empty?
                    item.text
                  else
                    item.css(@item_title_selector).text
                  end

      description = []
      @item_description_selectors.each do |desc_selector|
        description << item.css(desc_selector).text
      end

      @items << OpenStruct.new(
        url: link,
        title: title_str || "Unknown title",
        date: d,
        description: description.join("\n---\n")
      )
    end
    @items
  end

  def parse_config
    File.open(@filename, 'r') do |f|
      yaml = YAML.load(f.read)
      @url = yaml['url']
      @author = yaml['author']
      @browser = !!yaml['browser']
      @date_selector = yaml.dig('selectors', 'date')
      @date_extractor = yaml.dig('extractors', 'date')
      @title_selector = yaml.dig('selectors', 'title') || "head title"

      @item_selector = yaml.dig('selectors', 'item')
      @item_link_selector = yaml.dig('selectors', 'item_link')
      @item_title_selector = yaml.dig('selectors', 'item_title')
      @item_description_selectors = Array(yaml.dig('selectors', 'item_description'))

      @item_date_selector = yaml.dig('selectors', 'item_date')
      @item_date_extractor = yaml.dig('extractors', 'item_date')
    end
  end

  def first_node(node)
    case node
    when Nokogiri::XML::NodeSet then node[0]
    else node
    end
  end
end
