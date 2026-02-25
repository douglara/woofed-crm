class Accounts::UsersController < InternalController
  include UserConcern

  before_action :set_user, only: %i[edit update destroy hovercard_preview]

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
      flash[:notice] = t('flash_messages.updated', model: User.model_name.human)
      redirect_to edit_account_user_path(current_user.account, @user)
    else
      render :edit, status: :unprocessable_entity
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

  def combobox_select
    users = current_user.account.users.order(:full_name).map do |user|
      { id: user.id, full_name: user.full_name }
    end

    # Add "All users" option at the beginning
    all_option = { id: nil, full_name: I18n.t('activerecord.models.user.all') }
    users_with_all = [all_option] + users

    render inertia: 'Users/ComboboxSelect', props: {
      users: users_with_all,
      selected_user_id: params[:selected_user_id],
      input_name: params[:input_name] || 'filter[users_id_eq]',
      placeholder: params[:placeholder] || I18n.t('activerecord.models.user.select'),
      form_id: params[:form_id]
    }
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
