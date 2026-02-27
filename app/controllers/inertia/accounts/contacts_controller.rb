class Inertia::Accounts::ContactsController < Inertia::InternalController
  def search
    contacts = Contact.ransack(params[:query])

    @pagy, @contacts = pagy(contacts.result, metadata: %i[page items count pages from last to prev next])
    render json: { data: @contacts,
                   pagination: pagy_metadata(@pagy) }
  rescue ArgumentError => e
    render json: {
      errors: 'Invalid search parameters',
      details: e.message
    }, status: :unprocessable_entity
  end

  def index
    render inertia: 'v1/Contact/Index'
  end
end
