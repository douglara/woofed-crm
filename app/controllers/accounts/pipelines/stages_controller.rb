class Accounts::Pipelines::StagesController < InternalController
  before_action :set_pipeline
  before_action :set_stage, only: [:update_position]

  def new
    @stage = @pipeline.stages.build
  end

  def create
    @stage = @pipeline.stages.build(stage_params)
    
    respond_to do |format|
      if @stage.save
        format.html { redirect_to account_pipeline_path(Current.account, @pipeline), notice: t('flash_messages.created', model: Stage.model_name.human) }
        format.turbo_stream { render turbo_stream: turbo_stream.replace(:stages, partial: 'accounts/pipelines/stages_list') }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.turbo_stream { render turbo_stream: turbo_stream.replace(:stages, partial: 'accounts/pipelines/stages_list') }
      end
    end
  end

  def update_position
    new_position = params[:stage][:position].to_i
    @stage.insert_at(new_position)
    
    respond_to do |format|
      format.turbo_stream { redirect_to account_pipeline_path(Current.account, @pipeline) }
      format.html { redirect_to account_pipeline_path(Current.account, @pipeline) }
    end
  end

  private

  def set_pipeline
    @pipeline = Pipeline.find(params[:pipeline_id])
  end

  def set_stage
    @stage = @pipeline.stages.find(params[:id])
  end

  def stage_params
    params.require(:stage).permit(:name, :background_color, :text_color)
  end
end
