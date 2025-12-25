module AccountConcern
  def permitted_account_params
    %i[name number_of_employees segment site_url woofbot_auto_reply currency_code deal_free_form_lost_reasons deal_allow_edit_lost_at_won_at]
  end
end
