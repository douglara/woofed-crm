class EventBuilder

  def initialize(user, params)
    @params = params
    @user = user
    @account = user.account
  end

  def build
    @event = @user.account.events.new(@params)
    set_contact
    set_deal
    @event.done = true if @event.kind == 'note'
    # clean_html_codes()
    build_files if @params.key?('files')
    @event
  end

  def clean_html_codes
    if @event.content.present? && @event.kind != 'note'
      @event.content.body = ''
    end
  end

  def set_contact
    if @params.key?(:contact_id)
      @contact = @account.contacts.find(@params[:contact_id])
      @event.contact = @contact
    end
  end

  def set_deal
    if @params.key?(:deal_id)
      @deal = @account.deals.find(@params[:deal_id])
      @event.deal = @deal
    end
  end

  def build_files
    result = @params['files'].map.with_index do |file, index|
      if index.zero?
        @event = set_attachment(@event, file)
        next
      else
        file_event_params = @params.except(:content, :files)
        file_event = EventBuilder.new(@user,file_event_params).build
        file_event = set_attachment(file_event, file)
        file_event
      end
    end

    @event.files_events = result.compact
  end

  def set_attachment(event, file)
    begin
      attachment = event.build_attachment
      attachment.file = file
      attachment.file_type = attachment.file.content_type.split('/').first
      return event
    rescue
      @event.invalid_files = true

      return event
    end
  end
end
