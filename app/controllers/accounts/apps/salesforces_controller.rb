class Accounts::Apps::SalesforcesController < InternalController
  def create
    salesforce = Apps::Salesforce.first || Apps::Salesforce.new
    salesforce.assign_attributes(salesforce_params)

    return redirect_with_alert(salesforce.errors.full_messages.to_sentence) unless salesforce.save

    authorization = Apps::Salesforce::Oauth::AuthorizeRequest.new(salesforce).call
    # The verifier proves, at callback time, that this install started the flow.
    # It never leaves Woofed.
    session[:salesforce_oauth] = {
      'state' => authorization[:state],
      'code_verifier' => authorization[:code_verifier]
    }

    redirect_to authorization[:url], allow_other_host: true
  end

  def destroy
    Apps::Salesforce.first&.destroy

    redirect_to account_settings_path(current_user.account), notice: t('apps.salesforce.disconnected')
  end

  private

  def redirect_with_alert(message)
    redirect_to account_settings_path(current_user.account), alert: message
  end

  def salesforce_params
    params.require(:apps_salesforce).permit(:name, :environment, :client_id, :client_secret)
  end
end
