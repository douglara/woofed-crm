# Rows that failed or conflicted are kept with their payload, so resolving one is
# a matter of loading it again -- after the user fixed the mapping in Woofed, or
# the record in Salesforce.
class Inertia::Accounts::Apps::Salesforces::SyncRecordsController < Inertia::InternalController
  def retry
    sync_record = Apps::Salesforce::SyncRecord.find_by(id: params[:id])

    return redirect_back_with_alert(t('apps.salesforce.sync_records.not_found')) if sync_record.blank?

    sync_record.update!(status: 'pending', error: nil, processed_at: nil)
    Apps::Salesforce::Load::Record.new(sync_record).call

    redirect_to account_apps_salesforce_path(current_user.account),
                notice: t("apps.salesforce.sync_records.#{sync_record.reload.status}")
  end

  private

  def redirect_back_with_alert(message)
    redirect_to account_apps_salesforce_path(current_user.account), alert: message
  end
end
