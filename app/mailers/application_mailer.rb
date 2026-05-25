class ApplicationMailer < ActionMailer::Base
  layout 'mailer'

  before_action :attach_logo

  private

  def user_locale
    @user&.language.presence || I18n.default_locale
  end

  def attach_logo
    attachments.inline['logo.png'] = Rails.root.join('app/assets/images/logo.png').read
  end
end
