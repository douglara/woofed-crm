class Accounts::UsersController < InternalController
  before_action :set_user, only: %i[edit update destroy]

  def index
    @users = current_user.account.users
    @pagy, @users = pagy(@users)
  end

  def edit; end

  def update
    params_without_blank_password = user_params.reject { |key, value| value.blank? && key.include?('password') }

    if @user.update(params_without_blank_password)
      flash[:notice] = 'Usuário atualizado com sucesso!'
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
    @user.destroy
    flash[:notice] = 'User deleted successfully'
  end

  private

  def set_user
    @user = current_user.account.users.find(params[:id])
  end

  def user_params
    params.require(:user).permit(:email, :password, :password_confirmation, :full_name, :phone)
  end
end
