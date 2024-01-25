class EvolutionApiBuilder
  def initialize(user, params)
    @params = params
    @user = user
  end

  def build
    @evolution_api = @user.account.apps_evolution_apis.new(@params)
    @evolution_api.instance = @evolution_api.generate_token('instance')
    @evolution_api.token = @evolution_api.generate_token('token')
    @evolution_api.endpoint_url = ENV['EVOLUTION_API_ENDPOINT']
    @evolution_api
  end
end
