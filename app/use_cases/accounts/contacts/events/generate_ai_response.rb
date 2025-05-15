class Accounts::Contacts::Events::GenerateAiResponse
  def initialize(event)
    @event = event
    @account = event.account
    @ai_assistent = Apps::AiAssistent.first
  end

  def call
    return '' if @ai_assistent.exceeded_usage_limit?

    question = @event.content.to_s
    context = get_context(question)
    data = prepare_data(context, question)
    response = post_request(data)
    response_body = JSON.parse(response.body)
    update_ai_usage(response_body['usage']['total_tokens'])
    content = response_body.dig('output', 0, 'content', 0, 'text')
    JSON.parse(content)['response']
  rescue StandardError
    ''
  end

  def update_ai_usage(tokens)
    @ai_assistent.usage['tokens'] += tokens
    @ai_assistent.save
  end

  def get_context(query)
    embedding = OpenAi::Embeddings.new.get_embedding(@ai_assistent, query, 'text-embedding-3-small')
    documents = EmbeddingDocumment.nearest_neighbors(:embedding, embedding, distance: 'cosine').first(6)
    documents.pluck(:content, :source_reference)
  end

  def post_request(data)
    Rails.logger.info "Requesting Chat GPT with body: #{data}"
    response = Faraday.post(
      'https://api.openai.com/v1/responses',
      data.to_json,
      headers
    )
    Rails.logger.info "Chat GPT response: #{response.body}"
    response
  end

  def headers
    {
      'Content-Type' => 'application/json',
      'Authorization' => "Bearer #{@ai_assistent.api_key}"
    }
  end

  def prepare_data(context, question)
    {
      model: @ai_assistent.model,
      input: build_prompt(context, question),
      text: response_format,
      max_output_tokens: 2048,
      temperature: 0.3,
    }
  end

  def response_format
    {
      format: {
        type: 'json_schema',
        name: 'suggestion',
        schema: {
          type: 'object',
          properties: {
            response: {
              type: 'string'
            },
            confidence: {
              type: 'integer'
            }
          },
          required: %w[response confidence],
          additionalProperties: false
        },
        strict: true
      }
    }
  end

  def build_prompt(context, question)
    system_prompt_message = <<~SYSTEM_PROMPT_MESSAGE
      You are an assistant that will help answer questions from potential customers.
      Only respond if you are 100% certain; otherwise, your response should be left blank.
      If it is relevant to the response, include the link to the page where the information was found so the user can obtain more details.
      Respond in the language the customer used to ask the question.
      Never make up information.
      Respond in a short and objective manner, always in plain text, without Markdown formatting, without lists, without bold text, without formatted code, and without special symbols.
    SYSTEM_PROMPT_MESSAGE

    user_prompt_message = <<~USER_PROMPT_MESSAGE
      Context sections:
      #{context}

      Question:
      #{question}
    USER_PROMPT_MESSAGE

    [
      {
        role: 'system',
        content: system_prompt_message
      },
      {
        role: 'user',
        content: user_prompt_message
      }
    ]
  end
end
