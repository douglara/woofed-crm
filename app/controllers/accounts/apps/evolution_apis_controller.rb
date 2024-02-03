class Accounts::Apps::EvolutionApisController < InternalController
  before_action :set_evolution_api, only: %i[ edit update ]

  def new
    @evolution_api = Apps::EvolutionApi.new
  end

  def create
    result = Accounts::Apps::EvolutionApis::Create.call(current_user, evolution_api_params)
    @evolution_api = result[result.keys.first]
    respond_to do |format|
      if result.key?(:ok)
        format.html { redirect_to account_apps_evolution_api_pair_qr_code_path(current_user.account, @evolution_api.id) }
        format.json { render :create, status: :created }
      else
        @evolution_api = result[:error]
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @evolution_api[:error].errors, status: :unprocessable_entity }
      end
    end
  end

  def index
    @evolution_apis = current_user.account.apps_evolution_apis.order(updated_at: :desc)
    @pagy, @evolution_apis = pagy(@evolution_apis)
  end

  def edit
  end

  def update
    if @evolution_api.update(evolution_api_params)
      flash[:notice] = 'Whatsapp updated successfully!'
      redirect_to edit_account_apps_evolution_api_path(current_user.account, @evolution_api)
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def pair_qr_code
    @evolution_api = current_user.account.apps_evolution_apis.find(params['evolution_api_id'])
  end

  private
    def set_evolution_api
      @evolution_api = current_user.account.apps_evolution_apis.find(params[:id])
    end

    def evolution_api_params
      params.require(:apps_evolution_api).permit(:name, :token, :instance, :endpoint_url)
    end
end