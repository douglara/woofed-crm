require 'faraday/follow_redirects'

class Accounts::Create::PageCrawler
  attr_reader :page_link

  def initialize(page_link)
    @page_link = page_link

    conn = Faraday.new() do |faraday|
      faraday.response :follow_redirects
      faraday.adapter Faraday.default_adapter
    end

    @response = conn.get(page_link)
    @doc = Nokogiri::HTML(@response.body)
  end

  def valid_page?
    @response.status == 200 && @doc.at_xpath('//body').present?
  end

  def page_links
    sitemap? ? extract_links_from_sitemap : extract_links_from_html
  end

  def page_title
    title_element = @doc.at_xpath('//title')
    title_element&.text&.strip
  end

  def body_text_content
    ReverseMarkdown.convert @doc.at_xpath('//body'), unknown_tags: :bypass, github_flavored: true
  end

  private

  def sitemap?
    @page_link.end_with?('.xml')
  end

  def extract_links_from_sitemap
    @doc.xpath('//loc').to_set(&:text)
  end

  def extract_links_from_html
    @doc.xpath('//a/@href').to_set do |link|
      absolute_url = URI.join(@page_link, URI::Parser.new.escape(link.value)).to_s
      absolute_url
    end
  end
end
