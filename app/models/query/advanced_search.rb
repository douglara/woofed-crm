class Query::AdvancedSearch
  def initialize(current_user, current_account, params)
    raise ArgumentError, 'current_user is required' if current_user.blank?
    raise ArgumentError, 'current_account is required' if current_account.blank?
    raise ArgumentError, 'params is required' if params.blank?

    @current_user = current_user
    @current_account = current_account
    @params = params
    @limit = 7
  end

  def call
    case search_type
    when 'contact'
      { contacts: filter_contacts }
    when 'deal'
      { deals: filter_deals }
    when 'product'
      { products: filter_products }
    when 'pipeline'
      { pipelines: filter_pipelines }
    when 'activity'
      { activities: filter_activities }
    else
      { contacts: filter_contacts, deals: filter_deals, products: filter_products, pipelines: filter_pipelines,
        activities: filter_activities }
    end
  end

  private

  attr_reader :current_user, :current_account, :params, :limit

  def filter_contacts
    scope = Contact

    if search_query.present?
      pattern = "%#{search_query}%"
      scope = scope.where(
        'full_name ILIKE :q OR email ILIKE :q OR phone ILIKE :q',
        q: pattern
      )
    end

    scope.reorder('updated_at DESC').limit(limit)
  end

  def filter_deals
    scope = Deal

    if search_query.present?
      pattern = "%#{search_query}%"
      scope = scope.where(
        'name ILIKE :q',
        q: pattern
      )
    end

    scope.reorder('updated_at DESC').limit(limit)
  end

  def filter_products
    scope = Product

    if search_query.present?
      pattern = "%#{search_query}%"
      scope = scope.where(
        'name ILIKE :q OR identifier ILIKE :q',
        q: pattern
      )
    end

    scope.reorder('updated_at DESC').limit(limit)
  end

  def filter_pipelines
    scope = Pipeline

    if search_query.present?
      pattern = "%#{search_query}%"
      scope = scope.where(
        'name ILIKE :q',
        q: pattern
      )
    end

    scope.reorder('updated_at DESC').limit(limit)
  end

  def filter_activities
    scope = Event.activity

    if search_query.present?
      pattern = "%#{search_query}%"
      scope = scope.where(
        'title ILIKE :q',
        q: pattern
      )
    end

    scope.reorder('updated_at DESC').limit(limit)
  end

  def search_type
    @search_type ||= params[:search_type]&.downcase
  end

  def search_query
    @search_query ||= params[:q].to_s.strip
  end
end
