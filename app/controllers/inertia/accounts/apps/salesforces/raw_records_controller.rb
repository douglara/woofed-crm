# Rows that failed or conflicted are kept with their payload, so resolving one is
# a matter of loading it again -- after the user fixed the mapping in Woofed, or
# the record in Salesforce.
class Inertia::Accounts::Apps::Salesforces::RawRecordsController < Inertia::InternalController
  def retry
    raw_record = Apps::Salesforce::RawRecord.find_by(id: params[:id])

    return redirect_back_with_alert(t('apps.salesforce.raw_records.not_found')) if raw_record.blank?

    raw_record.update!(status: 'pending', error: nil, processed_at: nil)
    Apps::Salesforce::Load::Record.new(raw_record).call

    redirect_to account_apps_salesforce_path(current_user.account),
                notice: t("apps.salesforce.raw_records.#{raw_record.reload.status}")
  end

  private

  def redirect_back_with_alert(message)
    redirect_to account_apps_salesforce_path(current_user.account), alert: message
  end
end
