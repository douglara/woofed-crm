# frozen_string_literal: true

class OpenAi::Embeddings
  def get_embedding(ai_assistent, content, model = 'text-embedding-ada-002')
    fetch_embeddings(ai_assistent, content, model)
  end

  private

  def fetch_embeddings(ai_assistent, input, model)
    url = 'https://api.openai.com/v1/embeddings'
    headers = {
      'Authorization' => "Bearer #{ai_assistent.api_key}",
      'Content-Type' => 'application/json'
    }
    data = {
      input: input,
      model: model
    }

    response = Net::HTTP.post(URI(url), data.to_json, headers)
    JSON.parse(response.body)['data']&.pick('embedding')
  end
end
