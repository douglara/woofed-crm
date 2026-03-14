class Accounts::Settings::Plugins::ChatController < InternalController
  skip_before_action :verify_authenticity_token

  def create
    plugin = Current.account.plugins.find(params[:plugin_id])
    messages = JSON.parse(request.body.read)['messages'] || []

    ai_assistent = Apps::AiAssistent.first
    unless ai_assistent&.api_key.present?
      render json: { error: 'AI not configured' }, status: :unprocessable_entity
      return
    end

    system_message = build_system_message(plugin)

    response.headers['Content-Type'] = 'text/plain; charset=utf-8'
    response.headers['Cache-Control'] = 'no-cache'
    response.headers['X-Accel-Buffering'] = 'no'

    stream_openai_response(ai_assistent, system_message, messages)
  end

  private

  def build_system_message(plugin)
    <<~SYSTEM
      Você é um assistente de IA especializado em desenvolvimento de plugins para o WoofedCRM.
      Você está construindo o seguinte plugin:

      **Nome:** #{plugin.name}
      **Descrição:** #{plugin.description.presence || 'Não informada'}

      **Prompt do plugin:**
      #{plugin.prompt}

      Seu papel é:
      1. Analisar o prompt acima e planejar a implementação do plugin
      2. Apresentar o que está sendo feito passo a passo (análise, arquitetura, implementação)
      3. Responder perguntas do usuário sobre o plugin
      4. Simular o processo de construção com detalhes técnicos

      Responda sempre em português brasileiro de forma clara e detalhada.
    SYSTEM
  end

  def stream_openai_response(ai_assistent, system_message, user_messages)
    openai_messages = [
      { role: 'system', content: system_message },
      *user_messages.map { |m| { role: m['role'], content: m['content'] } }
    ]

    uri = URI('https://api.openai.com/v1/chat/completions')
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.read_timeout = 120

    body = {
      model: ai_assistent.model.presence || 'gpt-4o',
      messages: openai_messages,
      stream: true,
      max_tokens: 4096,
      temperature: 0.7
    }.to_json

    headers = {
      'Content-Type' => 'application/json',
      'Authorization' => "Bearer #{ai_assistent.api_key}"
    }

    request = Net::HTTP::Post.new(uri.path, headers)
    request.body = body

    self.response_body = Enumerator.new do |yielder|
      http.request(request) do |res|
        res.read_body do |chunk|
          chunk.split("\n").each do |line|
            next unless line.start_with?('data: ')

            data = line.sub('data: ', '').strip
            next if data == '[DONE]'

            begin
              parsed = JSON.parse(data)
              delta = parsed.dig('choices', 0, 'delta', 'content')
              finish = parsed.dig('choices', 0, 'finish_reason')

              if delta.present?
                # Vercel AI SDK text stream protocol
                yielder << "0:#{delta.to_json}\n"
              elsif finish.present?
                yielder << "d:{\"finishReason\":\"#{finish}\"}\n"
              end
            rescue JSON::ParseError
              # skip malformed chunks
            end
          end
        end
      end
    end
  end
end
