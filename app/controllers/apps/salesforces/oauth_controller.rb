# The callback URL is fixed for the whole install, because the customer registers
# it by hand in their External Client App. It therefore carries no account id and
# relies on the signed-in session to know where to send the user back to.
class Apps::Salesforces::OauthController < InternalController
  def callback
    return redirect_with_alert(salesforce_error_message) if params[:error].present?
    return redirect_with_alert(t('apps.salesforce.missing_connection')) if salesforce.blank?
    return redirect_with_alert(t('apps.salesforce.invalid_state')) unless valid_state?

    result = exchange_code
    session.delete(:salesforce_oauth)

    return redirect_with_alert(result[:error]) if result.key?(:error)

    redirect_to account_apps_salesforce_path(current_user.account), notice: t('apps.salesforce.connected')
  end

  private

  def exchange_code
    Apps::Salesforce::Oauth::ExchangeCode.call(
      salesforce,
      code: params[:code],
      code_verifier: oauth_session['code_verifier']
    )
  end

  def salesforce
    @salesforce ||= Apps::Salesforce.first
  end

  def oauth_session
    session[:salesforce_oauth].presence || {}
  end

  # Guards against a callback that this browser session did not start.
  def valid_state?
    stored_state = oauth_session['state'].to_s

    stored_state.present? && ActiveSupport::SecurityUtils.secure_compare(stored_state, params[:state].to_s)
  end

  def salesforce_error_message
    Apps::Salesforce::Oauth::ErrorMessage.call(params[:error], redirect_uri: apps_salesforces_oauth_callback_url)
  end

  def redirect_with_alert(message)
    redirect_to account_apps_salesforce_path(current_user.account), alert: message
  end
end
