class Accounts::UsersController < InternalController
  include UserConcern

  before_action :set_user, only: %i[show edit update destroy hovercard_preview]

  def show
    @pagy_deals, @deals = pagy(@user.deals.order(created_at: :desc), items: 10, page_param: :deals_page)
  end

  def index
    @users = if params[:query].present?
              User.where(
                'full_name ILIKE :search OR email ILIKE :search OR phone ILIKE :search', search: "%#{params[:query]}%"
              ).order(updated_at: :desc)
             else
              User.all.order(created_at: :desc)
             end

    @pagy, @users = pagy(@users)
  end

  def edit; end

  def update
    params_without_blank_password = user_params.reject { |key, value| value.blank? && key.include?('password') }

    if @user.update(params_without_blank_password)
      respond_to do |format|
        format.html do
          flash[:notice] = t('flash_messages.updated', model: User.model_name.human)
          redirect_to edit_account_user_path(current_user.account, @user)
        end
        format.json { head :ok }
      end
    else
      respond_to do |format|
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: { errors: @user.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  def new
    @user = User.new
  end

  def create
    @user = current_user.account.users.new(user_params)
    if @user.save
      redirect_to account_users_path(current_user.account),
                  notice: t('flash_messages.created', model: User.model_name.human)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    if @user.destroy
      redirect_to account_users_path(current_user.account),
                  notice: t('flash_messages.deleted', model: User.model_name.human)
    end
  end

  def select_user_search
    @users = if params[:query].present?
               User.where(
                 'full_name ILIKE :search OR email ILIKE :search OR phone ILIKE :search', search: "%#{params[:query]}%"
               ).order(updated_at: :desc).limit(5)
             else
               User.order(updated_at: :desc).limit(5)
             end
  end

  def hovercard_preview
  end

  private

  def set_user
    @user = current_user.account.users.find(params[:id])
  end

  def user_params
    params.require(:user).permit(*permitted_user_params)
  end
end
