# frozen_string_literal: true

module Installation::Complete
  def complete_installation!
    return unless Installation.installation_flow?
    return unless register_completed_install

    completed!
    app_reload
    true
  end

  def register_completed_install
    return false if Current.account.blank?

    user = self.user

    result_request = Faraday.post(
      'https://store.woofedcrm.com/installations/complete',
      {
        user_details: { name: user.full_name, email: user.email,
                        phone_number: user.phone, job_description: user.job_description },
        company_details: { name: Current.account.name, site_url: Current.account.site_url,
                           segment: Current.account.segment, number_of_employees: Current.account.number_of_employees }
      }.to_json,
      { 'Content-Type' => 'application/json', 'Authorization' => "Bearer #{token}" }
    )

    result_request.status == 200
  end

  def app_reload
    load "#{Rails.root}/app/controllers/application_controller.rb"
    Rails.application.reload_routes!
  end
end
