class Accounts::Apps::EvolutionApis::Create
  def self.call(user, evolution_apis_params)
		evolution_api = EvolutionApiBuilder.new(user, evolution_apis_params).build
		if evolution_api.save
      Accounts::Apps::EvolutionApis::Instance::Create.call(evolution_api)
			return { ok: evolution_api }
		else
			return { error: evolution_api }
		end
  end
end
