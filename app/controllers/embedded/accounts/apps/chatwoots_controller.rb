class Embedded::Accounts::Apps::ChatwootsController < Embedded::InternalController
  def index
    #redirect_to account_contact_note_path(@current_account, @current_account.contacts.first)
    redirect_to root_path
  end
end