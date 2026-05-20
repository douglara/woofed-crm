class ApplicationTool < ActionTool::Base
  include Pagy::Backend
  include Mcp::Concerns::RequestExceptionHandler

  def current_user
    Current.user
  end

  def current_account
    Current.account
  end

  def paginate(scope, page: 1, per_page: 25)
    per_page = per_page.to_i.clamp(1, 100)
    pagy_obj, records = pagy(scope, page: page.to_i, items: per_page)
    pagination = {
      page: pagy_obj.page,
      items: pagy_obj.items,
      count: pagy_obj.count,
      pages: pagy_obj.pages,
      from: pagy_obj.from,
      to: pagy_obj.to,
      prev: pagy_obj.prev,
      next: pagy_obj.next,
      last: pagy_obj.last
    }
    [records, pagination]
  end
end
