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
      @contact = @current_user.account.contacts.create!(contact_params)
      status = :created
    else
      existing_contact.update!(contact_params)
      @contact = existing_contact
      status = :ok
    end 
    render json: @contact, status: status
  end

  def contact_params
    params.permit(:full_name, :phone, :email)
  end
end