class ProductBuilder
  def initialize(user, params)
    @params = params
    @user = user
  end

  def build
    @product = @user.account.products.new(@params)
    build_files if @params.key?('files')
    @product
  end

  def perform
    build
    @product
  end

  def build_files
    @params[:files].each do |file|
      config_attachment(file)
    end
  end

  # def config_attachment(file)
  #   attachment = @product.build_attachment
  #   attachment.file = file
  #   attachment.file_type = attachment.check_file_type
  # rescue StandardError
  #   @product.invalid_files = true
  # end
end
