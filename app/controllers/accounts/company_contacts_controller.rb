class Accounts::CompanyContactsController < InternalController
  before_action :set_company_contact, only: %i[destroy]

  def create
    # The page the link was created from: 'company' (pick a contact) or 'contact' (pick a company).
    # Our form always sends it; anything else falls back to the company side, which is where the
    # HTML redirect points too.
    @origin = params[:origin].presence || 'company'
    @company_contact = CompanyContact.new(company_contact_params)
    if @company_contact.save
      respond_to do |format|
        format.html do
          redirect_to account_company_path(current_user.account, @company_contact.company),
                      notice: t('flash_messages.added', model: Contact.model_name.human)
        end
        format.turbo_stream
      end
    else
      # The form owns a frame inside the modal, so re-rendering it alone swaps the errors in
      # place; re-rendering the whole modal would be discarded as it is data-turbo-permanent.
      render partial: 'accounts/company_contacts/form',
             locals: { company_contact: @company_contact, origin: @origin },
             status: :unprocessable_entity
    end
  end

  def destroy
    return unless @company_contact.destroy

    respond_to do |format|
      format.html do
        redirect_to account_company_path(current_user.account, @company_contact.company),
                    notice: t('flash_messages.deleted', model: Contact.model_name.human)
      end
      format.turbo_stream
    end
  end

  private

  def company_contact_params
    params.require(:company_contact).permit(:company_id, :contact_id)
  end

  def set_company_contact
    @company_contact = CompanyContact.find(params[:id])
  end
end
