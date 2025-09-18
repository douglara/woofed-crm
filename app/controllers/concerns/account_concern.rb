module AccountConcern
  def permitted_account_params
    %i[name number_of_employees segment site_url woofbot_auto_reply currency_code]
  end
end
