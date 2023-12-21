class EventBuilder

  def initialize(user, params)
    @params = params.except(:send_now)
    @user = user
    @send_now = params['send_now'].in?(['true', '1'])
  end

  def build
    @event = @user.account.events.new(@params)
    @event.done = true if @event.kind == 'note'
    @event.scheduled_at = Time.now if @send_now
    # clean_html_codes()   
    @event
  end

  def clean_html_codes
    if @event.content.present? && @event.kind != 'note'
      @event.content.body = ''
    end
  end
end