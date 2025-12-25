class Accounts::DealsController < InternalController
  include DealProductConcern
  include DealConcern

  before_action :set_deal,
                only: %i[show edit update destroy events_to_do events_done deal_products deal_assignees mark_as_lost mark_as_won]
  before_action :set_deal_product, only: %i[edit_deal_product
                                            update_deal_product]

  # GET /deals or /deals.json
  def index
    @first_pipeline = Pipeline.first
    @deals = if params[:query].present?
              Deal.left_joins(:contact)
                  .where(
                    'deals.name ILIKE :search OR ' +
                    'contacts.full_name ILIKE :search OR ' +
                    'deals.id = :id',
                    search: "%#{params[:query]}%",
                    id: params[:query].to_i
                  )
                  .order(updated_at: :desc)
              else
                Deal.all.order(created_at: :desc)
              end

    @pagy, @deals = pagy(@deals)
  end

  # GET /deals/1 or /deals/1.json
  def show; end

  # GET /deals/new
  def new
    @deal = Deal.new
    @stages = Stage.ordered_by_pipeline_and_position
    @deal.contact_id = params.dig(:deal, :contact_id)

    if @deal.contact_id.blank?
      @deal.errors.add(:contact, :blank)
      render :new_select_contact, status: :unprocessable_entity
      return
    end
  end

  def new_select_contact
    @deal = Deal.new
  end

  def add_contact
    @deal = Deal.find(params[:deal_id])
  end

  def commit_add_contact
    @deal = Deal.find(params[:deal_id])
    @new_contact = Contact.find(params['deal']['contact_id'])
    @deal.contacts.push(@new_contact)

    if Deal::CreateOrUpdate.new(@deal, deal_params).call
      redirect_to account_deal_path(current_user.account, @deal)
    else
      render :add_contact, status: :unprocessable_entity
    end
  rescue StandardError
    render :add_contact, status: :unprocessable_entity
  end

  def remove_contact
    @deal = Deal.find(params[:deal_id])
    @contacts_deal = @deal.contacts_deals.find_by_contact_id(params['contact_id'])

    if @contacts_deal.destroy
      redirect_to account_deal_path(current_user.account, @deal)
    else
      render :show, status: :unprocessable_entity
    end
  rescue StandardError
    render :show, status: :unprocessable_entity
  end

  # GET /deals/1/edit
  def edit
    @stages = Stage.ordered_by_pipeline_and_position
  end

  def edit_custom_attributes
    @deal = current_user.account.deals.find(params[:deal_id])
    @custom_attribute_definitions = current_user.account.custom_attribute_definitions.deal_attribute
  end

  # POST /deals or /deals.json
  def create
    @stages = Stage.ordered_by_pipeline_and_position
    @deal = DealBuilder.new(current_user, deal_params).perform

    if Deal::CreateOrUpdate.new(@deal, deal_params).call
      redirect_to account_deal_path(current_user.account, @deal)
    else
      render :new, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /deals/1 or /deals/1.json
  def update
    @stages = Stage.ordered_by_pipeline_and_position
    if params[:deal][:att_key].present?
      @deal.custom_attributes[params[:deal][:att_key]] = params[:deal][:att_value]
    end

    if Deal::CreateOrUpdate.new(@deal, deal_params).call
      respond_to do |format|
        format.html { redirect_to account_deal_path(current_user.account, @deal) }
        format.turbo_stream
      end
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /deals/1 or /deals/1.json
  def destroy
    @deal.destroy
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to root_path, notice: t('flash_messages.deleted', model: Deal.model_name.human) }
      format.json { head :no_content }
    end
  end

  def events_to_do
    @pagy, @events = pagy(@deal.contact.events.where(deal_id: [nil, @deal.id]).to_do, items: 5)
    respond_to do |format|
      format.turbo_stream
      format.html
    end
  end

  def events_done
    @pagy, @events = pagy(@deal.contact.events.where(deal_id: [nil, @deal.id]).done, items: 5)
    respond_to do |format|
      format.turbo_stream
      format.html
    end
  end

  def deal_products
    @deal_products = @deal.deal_products
  end

  def deal_assignees
    @deal_assignees = @deal.deal_assignees
  end

  def edit_deal_product
  end

  def update_deal_product
    if DealProduct::CreateOrUpdate.new(@deal_product, deal_product_params).call
      respond_to do |format|
        format.html do
          redirect_to deal_products_account_deal_path(current_user.account, @deal_product.deal)
        end
        format.turbo_stream
      end
    else
      render :edit_deal_product, status: :unprocessable_entity
    end
  end

  def mark_as_lost
    @stages = Stage.ordered_by_pipeline_and_position
    @lost_reasons = DealLostReason.order(:name).pluck(:name).uniq
    @exists_deal_lost_reasons = DealLostReason.exists?
    @allow_edit_lost_at = Current.account.deal_allow_edit_lost_at_won_at
  end

  def mark_as_won
    @stages = Stage.ordered_by_pipeline_and_position
    @allow_edit_won_at = Current.account.deal_allow_edit_lost_at_won_at
  end

  private

  def set_deal
    @deal = current_user.account.deals.find(params[:id])
  end

  def set_deal_product
    @deal_product = current_user.account.deal_products.find(params[:deal_product_id])
  end

  def deal_product_params
    params.require(:deal_product).permit(*permitted_deal_product_params)
  end

  # Only allow a list of trusted parameters through.
  def deal_params
    params.require(:deal).permit(*permitted_deal_params)
  end
end
