# frozen_string_literal: true

class Accounts::Apps::AiAssistentsController < InternalController
  before_action :set_ai_assistent

  def edit; end

  def update
    if @ai_assistent.update(ai_assistent_params)
      redirect_to edit_account_apps_ai_assistent_path(current_user.account),
                  notice: t('flash_messages.updated', model: Apps::AiAssistent.model_name.human)
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_ai_assistent
    @ai_assistent = Apps::AiAssistent.first.presence || Apps::AiAssistent.create
  end

  def ai_assistent_params
    params.require(:apps_ai_assistent).permit(:auto_reply, :model, :api_key, :enabled)
  end
end
