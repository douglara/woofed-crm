class EventBuilder

  def initialize(user, params)
    @params = params
    @user = user
  end

  def build
    @event = @user.account.events.new(@params)
    # clean_html_codes()   
    @event
  end

  def clean_html_codes
    if @event.content.present? && @event.kind != 'note'
      @event.content.body = ''
    end
  end
end