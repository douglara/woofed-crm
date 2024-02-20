class Api::V1::Accounts::ContactsController < Api::V1::InternalController
  def show
    @contact = @current_user.account.contacts.find(params["id"])

    if @contact
      render json: @contact, include: [:deals, :events], status: :ok
    else
      render json: { errors: 'Not found' }, status: :not_found
    end
  end

  def create
    @contact = @current_user.account.contacts.new(contact_params)

    if @contact.save
      render json: @contact, status: :created
    else
      render json: { errors: @contact.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def upsert
    existing_contact = Accounts::Contacts::GetByParams.call(@current_user.account, contact_params.to_h)[:ok]

    if existing_contact.nil?
      @contact = @current_user.account.contacts.new(contact_params)
      status = :created
    else
      @contact = existing_contact
      @contact.assign_attributes(contact_params)
      status = :ok
    end

    if @contact.save
      render json: @contact, status: status
    else
      render json: @contact.errors, status: :unprocessable_entity
    end
  end

  def search
    contacts = @current_user.account.contacts.ransack(params[:query])

    @pagy, @contacts = pagy(contacts.result, metadata: %i[page items count pages from last to prev next])
    render json: { data: @contacts,
                   pagination: pagy_metadata(@pagy) }
  end

  def contact_params
    params.permit(:full_name, :phone, :email, :label_list,
                  custom_attributes: {})
  end
end
