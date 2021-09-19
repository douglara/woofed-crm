class Settings::WhatsappController < InternalController
  before_action :set_activity_kind_whatsapp, only: %i[ edit deactivate new_connection new_connection_status ]

  def edit
  end

  def new_connection
    @activity_kind_whatsapp.update(new_connection_params) if params['activity_kind']
    @qr_code = Activities::Whatsapp::Connection::New.new.generate_qr_code

    respond_to do |format|
      if @qr_code.key?(:ok)
        format.html { render :new_connection}
        format.json { render :new_connection, status: :ok }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @activity_kind.errors, status: :unprocessable_entity }
      end
    end
  end

  def new_connection_status
    is_connected = Activities::Whatsapp::Connection::New.new.connected?
    @activity_kind_whatsapp['settings']['enabled'] = is_connected
    @activity_kind_whatsapp.save

    respond_to do |format|
      format.json { render json: {'connceted': is_connected}, status: :ok }
    end
  end

  def deactivate
    @activity_kind_whatsapp['settings']['enabled'] = false
    respond_to do |format|
      if @activity_kind_whatsapp.save
        format.html { redirect_to settings_whatsapp_edit_path(), notice: "Whatsapp activated" }
        format.json { render :edit, status: :ok, location: @contact }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @activity_kind.errors, status: :unprocessable_entity }
      end
    end
  end

  private
    def set_activity_kind_whatsapp
      @activity_kind_whatsapp = ActivityKind.find_by_key('whatsapp')
    end

    def activity_kind_params
      params.require(:activity_kind).permit(settings: {})
    end

    def new_connection_params
      params.require(:activity_kind).permit(settings: [:secretkey, :endpoint_url])
    end
end