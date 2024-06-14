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
    @params['files'].each do |file|
      set_attachment(file)
    end
  end

  def set_attachment(file)
    attachment = @product.attachments.build
    attachment.file = file
    attachment.file_type = attachment.check_file_type
    attachment.save
  rescue StandardError
    Rails.logger.error "Error saving attachment: #{attachment.file}"
  end
end
