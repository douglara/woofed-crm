class ApplicationMailer < ActionMailer::Base
  layout 'mailer'

  private

  def user_locale
    @user&.language.presence || I18n.default_locale
  end
end
