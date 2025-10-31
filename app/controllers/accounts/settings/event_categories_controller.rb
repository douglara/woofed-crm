class Accounts::Settings::EventCategoriesController < InternalController
  before_action :set_event_category, only: %i[edit update destroy]

  def index
    @account = Current.account
    @event_categories = Current.account.event_categories.order(:name)
  end

  def edit
    @account = Current.account
  end

  def update
    @account = Current.account
    if @event_category.update(event_category_params)
      respond_to do |format|
        format.html do
          redirect_to edit_account_settings_event_category_path(Current.account, @event_category),
                      notice: t('flash_messages.updated', model: EventCategory.model_name.human)
        end
        format.turbo_stream
      end
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def new
    @account = Current.account
    @event_category = Current.account.event_categories.new
  end

  def create
    @account = Current.account
    @event_category = Current.account.event_categories.new(event_category_params)
    if @event_category.save
      respond_to do |format|
        format.html do
          redirect_to account_settings_event_categories_path(Current.account),
                      notice: t('flash_messages.created', model: EventCategory.model_name.human)
        end
        format.turbo_stream
      end
    else
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    if @event_category.destroy
      respond_to do |format|
        format.html do
          redirect_to account_settings_event_categories_path(Current.account),
                      notice: t('flash_messages.deleted', model: EventCategory.model_name.human)
        end
      end
    else
      respond_to do |format|
        format.html do
          redirect_to account_settings_event_categories_path(Current.account),
                      flash: { error: @event_category.errors.full_messages.to_sentence }
        end
      end
    end
  end

  private

  def set_event_category
    @event_category = Current.account.event_categories.find(params[:id])
  end

  def event_category_params
    params.require(:event_category).permit(:name, :icon, :color)
  end
end
