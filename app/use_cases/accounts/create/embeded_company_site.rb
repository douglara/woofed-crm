class Accounts::Create::EmbededCompanySite
  def initialize(account)
    @account = account
    @ai_assistent = Apps::AiAssistent.first
    @start_url = @account.site_url
    @start_url_host = URI.parse(@start_url).host
  end

  def call(max_pages = 100)
    crawl_website(@start_url, max_pages)
  end

  private

  def clean_data
    @account.embedding_documments.where(source: @account).destroy_all
  end

  def crawl_website(start_url, max_pages)
    visited = []
    queue = [start_url]

    pages_visited = 0

    while !queue.empty? && pages_visited < max_pages
      current_url = queue.shift
      next if visited.include?(current_url)
      visited.push(current_url)

      begin
        page = Accounts::Create::PageCrawler.new(current_url)
        next unless page.valid_page?

        embed_page(page)
        links = filter_site_subpages(page.page_links) - visited

        links.each do |link|
          queue << link
        end

        pages_visited += 1
      rescue => e
        puts "Failed to fetch #{current_url}: #{e.message}"
      end
    end

    visited
  end

  def embed_page(page)
    splitter = ::TextSplitters::RecursiveCharacterTextSplitter.new(chunk_size: 1000, chunk_overlap: 100)
    page_filter_links = page.body_text_content.gsub(/\[(.*?)\]\(.*?\)/m, '')
    output = splitter.split(page_filter_links)

    output.each do |content_split|
      @account.embedding_documments.create(
        source_reference: page.page_link,
        source: @account,
        content: content_split,
        embedding: OpenAi::Embeddings.new.get_embedding(@ai_assistent, content_split, 'text-embedding-3-small')
      )
    end
  end

  def filter_site_subpages(links)
    links.filter do |link|
      link.include?(@start_url_host)
    end
  end
end
