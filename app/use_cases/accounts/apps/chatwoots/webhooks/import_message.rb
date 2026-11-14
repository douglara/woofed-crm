class Accounts::Apps::Chatwoots::Webhooks::ImportMessage
  require 'open-uri'
  require 'ipaddr'
  require 'resolv'

  def initialize(chatwoot, contact, webhook)
    @chatwoot = chatwoot
    @contact = contact
    @webhook =  webhook
  end

  def call
    message = get_or_import_message()
    { ok: message }
  end

  def get_or_import_message()
    message = @contact.events.where(
      '? <@ additional_attributes', { chatwoot_id: @webhook['id'] }.to_json
    ).first
    if message.nil?
      if attachments?
        message = import_message_with_attachments()
      else
        message = import_message()
      end
    end
    message
  end

  def import_message_with_attachments()
    @webhook['attachments'].reverse.map.with_index do |attachment, index|
      import_message(
        { attachment: attachment, order: index, last_element: last_element?(index)}
        )
    end
  end

  def last_element?(index)
    index == @webhook['attachments'].count - 1
  end

  def import_message(attachment_params = {})
    message = @contact.events.new(
      account: @chatwoot.account,
      kind: 'chatwoot_message',
      from_me: is_from_me?(),
      contact: @contact,
      done: true,
      done_at: build_done_at(attachment_params[:order]),
      app: @chatwoot
    )
    message.additional_attributes.merge!({ 'chatwoot_id' => @webhook['conversation']['messages'].first['id'] })

    if attachment_params.present?
      create_attachment(message, attachment_params[:attachment])
      message.content = @webhook['content'] if attachment_params[:last_element] == true
    else
      message.content = @webhook['content']
    end

    message.save
    message
  end

  def create_attachment(event, attachment_params)
    begin
      data_url = attachment_params['data_url']
      unless fetchable_url?(data_url)
        event.status = 'failed'
        return
      end
      downloaded_file = URI.open(data_url)
      attachment = event.build_attachment(
        file_type: attachment_params['file_type']
      )
      attachment.file.attach(io: downloaded_file,
                             filename: File.basename(data_url))
    rescue OpenURI::HTTPError
      event.status = 'failed'
    end
  end

  # Only allow fetching public http(s) URLs. The attachment metadata (including
  # data_url) comes straight from the inbound webhook payload, so without this
  # guard a crafted payload could point data_url at an internal address
  # (127.0.0.1, 169.254.169.254, RFC1918, ...) and have the server fetch it.
  def fetchable_url?(url)
    uri = URI.parse(url.to_s)
    return false unless %w[http https].include?(uri.scheme)
    return false if uri.host.blank?

    addresses = Resolv.getaddresses(uri.host)
    return false if addresses.empty?

    addresses.none? { |ip| internal_ip?(ip) }
  rescue URI::InvalidURIError, Resolv::ResolvError
    false
  end

  def internal_ip?(ip)
    addr = IPAddr.new(ip.to_s)
    addr.loopback? || addr.private? || addr.link_local?
  rescue IPAddr::Error
    true
  end

  def build_done_at(order = nil)
    if order.present?
      created_at = @webhook['created_at'].dup
      created_at.to_time + miliseconds(order)
    else
      @webhook['created_at'].to_time
    end
  end

  def miliseconds(miliseconds)
    miliseconds/1000.0
  end

  def attachments?()
    @webhook['attachments'].present?
  end

  def is_from_me?()
    @webhook.dig('sender', 'type') == 'user' if @webhook.dig('sender', 'id').present?
  end
end
