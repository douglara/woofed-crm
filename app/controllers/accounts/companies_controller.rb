class Accounts::CompaniesController < InternalController
  include CompanyConcern

  before_action :set_company,
                only: %i[show edit update destroy edit_custom_attributes update_custom_attributes
                         new_company_contact]

  def index
    @companies = if params[:query].present?
                   Company.where(
                     'name ILIKE :search OR email ILIKE :search OR phone ILIKE :search', search: "%#{params[:query]}%"
                   ).order(updated_at: :desc)
                 else
                   Company.all.order(created_at: :desc)
                 end

    @pagy, @companies = pagy(@companies)
  end

  def show
    @company_contacts = @company.company_contacts.includes(:contact)
  end

  def new
    @company = Company.new
    @company.attachments.build
  end

  def create
    @company = Company.new(company_params)
    if @company.save
      @company_contacts = @company.company_contacts.includes(:contact)
      respond_to do |format|
        format.html do
          redirect_to account_company_path(current_user.account, @company),
                      notice: t('flash_messages.created', model: Company.model_name.human)
        end
        format.turbo_stream
      end
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @company.update(company_params)
      redirect_to account_company_path(current_user.account, @company),
                  notice: t('flash_messages.updated', model: Company.model_name.human)
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @company.destroy
    respond_to do |format|
      format.html do
        redirect_to account_companies_path(current_user.account),
                    notice: t('flash_messages.deleted', model: Company.model_name.human)
      end
      format.json { head :no_content }
    end
  end

  def edit_custom_attributes
    @custom_attribute_definitions = CustomAttributeDefinition.company_attribute
  end

  def update_custom_attributes
    @company.custom_attributes[params[:company][:att_key]] = params[:company][:att_value]
    render :edit_custom_attributes, status: :unprocessable_entity unless @company.save
  end

  def new_company_contact
    @company_contact = @company.company_contacts.new
  end

  def select_company_search
    @companies = if params[:query].present?
                   Company.where('name ILIKE :search', search: "%#{params[:query]}%").order(updated_at: :desc).limit(5)
                 else
                   Company.all.order(updated_at: :desc).limit(5)
                 end
  end

  private

  def set_company
    @company = Company.find(params[:id])
  end
end
