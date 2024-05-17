class ProductBuilder
  def initialize(user, params)
    @params = params
    @user = user
  end

  def build
    @product = @user.account.products.new(@params)
    @product
  end

  def perform
    build
    @product
  end
end
