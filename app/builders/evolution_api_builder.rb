class EvolutionApiBuilder
  def initialize(user, params)
    @params = params
    @user = user
  end

  def build
    @evolution_api = @user.account.apps_evolution_apis.new(@params)
    @evolution_api.name = @evolution_api.generate_token('name')
    @evolution_api.token = @evolution_api.generate_token('token')
    @evolution_api
  end
end
