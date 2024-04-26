class ProductBuilder
  def initialize(user, params)
    @params = params
    @user = user
  end

  def build
    @product = @user.account.products.new(@params)
    @product.amount_in_cents = convert_amount_in_cents if @params[:amount_in_cents].present?
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

  def convert_amount_in_cents
    @params[:amount_in_cents].gsub(/[^\d-]/, '').to_i
  end

  # def config_attachment(file)
  #   attachment = @product.build_attachment
  #   attachment.file = file
  #   attachment.file_type = attachment.check_file_type
  # rescue StandardError
  #   @product.invalid_files = true
  # end
end
