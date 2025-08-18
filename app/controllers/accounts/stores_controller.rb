class Accounts::StoresController < InternalController
  def show
    @store_base_url = ENV.fetch('STORE_URL', 'https://store.woofedcrm.com')
    @path = params[:path] || ''
    @store_url = "#{@store_base_url}/#{@path}"
  end
end
