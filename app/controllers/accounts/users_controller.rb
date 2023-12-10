class Accounts::UsersController < InternalController
  before_action :set_user, only: %i[edit update destroy]

  def index
    @users = current_user.account.users
    @pagy, @users = pagy(@users)
  end

  def edit; end

  def update
    if @user.update(user_params.compact_blank)
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
      redirect_to account_users_path(current_user.account), notice: 'User was successfully created.'
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
    params.require(:user).permit(:email, :password, :password_confirmation, :full_name)
  end
end
