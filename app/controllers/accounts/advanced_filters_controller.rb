class Accounts::AdvancedFiltersController < InternalController
  MODELS = {
    'deal' => Deal,
    'contact' => Contact,
    'user' => User,
    'product' => Product
  }.freeze

  def show
    model_class = MODELS[params[:model]] || Deal
    @model_class = model_class
    @redirect_url = params[:redirect_url]
    @fields = SchemaBuilder.build(model_class, @account, account_id: @account.id)
  end
end
