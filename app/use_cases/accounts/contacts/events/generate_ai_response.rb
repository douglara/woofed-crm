class Accounts::Contacts::Events::GenerateAiResponse
  def initialize(event)
    @event = event
    @account = event.account
  end

  def call
    return '' if @account.exceeded_account_limit?

    question = @event.content.to_s
    context = get_context(question)
    data = prepare_data(context, question)
    response = post_request(data)
    response_body = JSON.parse(response.body)
    update_ai_usage(response_body['usage']['total_tokens'])
    content = response_body.dig('choices', 0, 'message', 'content').gsub(/```json\n?|```/, '')
    JSON.parse(content)['response']
  rescue StandardError
    ''
  end

  def update_ai_usage(tokens)
    @account.ai_usage['tokens'] += tokens
    @account.save
  end

  def get_context(query)
    embedding = OpenAi::Embeddings.new.get_embedding(query, 'text-embedding-3-small')
    documents = EmbeddingDocumment.where(account_id: @account.id).nearest_neighbors(:embedding, embedding, distance: 'cosine').first(6)
    puts("Documents: #{documents.count}")
    documents.pluck(:content, :source_reference)
  end

  def post_request(data)
    Rails.logger.info "Requesting Chat GPT with body: #{data}"
    response = Faraday.post(
      'https://api.openai.com/v1/chat/completions',
      data.to_json,
      headers
    )
    Rails.logger.info "Chat GPT response: #{response.body}"
    response
  end

  def headers
    {
      'Content-Type' => 'application/json',
      'Authorization' => "Bearer #{ENV.fetch('OPENAI_API_KEY')}"
    }
  end

  def prepare_data(context, question)
    {
      model: 'gpt-4-turbo',
      temperature: 0.3,
      messages: [
        {
          role: 'user',
          content: build_prompt(context, question)
        }
      ]
    }
  end

  def build_prompt(context, question)
    <<~SYSTEM_PROMPT_MESSAGE
      Follow the rules:
      Your answers will always be formatted in valid JSON hash, as shown below. Never respond in non-JSON format.
      Answer in Brazilian Portuguese.
      Convert from Markdown to plain text.
      Only respond if you are 100% certain; otherwise, your response should be left blank.
      If it is relevant to the response, include the link to the page where the information was found so the user can obtain more details.

      Json format:
      {
        response: '',
        confidence: 1
      }

      Context sections:
      #{context}

      Question:
      #{question}"
    SYSTEM_PROMPT_MESSAGE
  end
end
