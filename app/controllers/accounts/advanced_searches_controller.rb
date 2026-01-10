class Accounts::AdvancedSearchesController < InternalController
  def index
  end

  def results
    @results = Query::AdvancedSearch.new(current_user, current_user.account, search_params).call
  end

  private

  def search_params
    params.permit(:q, :search_type)
  end
end
