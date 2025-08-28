class Api::V1::Accounts::ContactsController < Api::V1::InternalController
  def show
    @contact = Contact.find(params['id'])

    if @contact
      render json: @contact, include: %i[deals events], status: :ok
    else
      render json: { errors: 'Not found' }, status: :not_found
    end
  end

  def create
    @contact = Contact.new(contact_params)

    if @contact.save
      render json: @contact, status: :created
    else
      render json: { errors: @contact.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def upsert
    existing_contact = Accounts::Contacts::GetByParams.call(Account.first, contact_params.to_h)[:ok]

    if existing_contact.nil?
      @contact = Contact.new(contact_params)
      status = :created
    else
      @contact = existing_contact
      @contact.assign_attributes(contact_params)
      status = :ok
    end

    if @contact.save
      render(json: @contact, status:)
    else
      render json: @contact.errors, status: :unprocessable_entity
    end
  end

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

  def contact_params
    params.permit(:full_name, :phone, :email, :label_list,
                  custom_attributes: {})
  end
end
