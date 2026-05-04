class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch('MAILER_SENDER_EMAIL', 'WoofedCRM <hi@woofedcrm.com>')
  layout 'mailer'

  private

  def user_locale
    @user&.language.presence || I18n.default_locale
  end
end
