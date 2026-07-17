# frozen_string_literal: true

module CompanyConcern
  def company_params
    params.require(:company).permit(:name, :phone, :email, :label_list,
                                    attachments_attributes: %i[file _destroy id],
                                    custom_attributes: {}, additional_attributes: {})
  end
end
