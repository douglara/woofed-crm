require 'csv'
require 'json_csv'

class Accounts::PipelinesController < InternalController
  layout 'inertia', only: %i[show load_more_deals refresh_stage]

  before_action :set_pipeline, only: %i[show edit update destroy bulk_action new_bulk_action]
  before_action :set_bulk_action_event, only: %i[bulk_action new_bulk_action]
  before_action :set_stage, only: %i[bulk_action new_bulk_action]

  # GET /pipelines or /pipelines.json
  def index
    pipeline = Pipeline.first
    if pipeline
      redirect_to(account_pipeline_path(Current.account, pipeline))
    else
      redirect_to account_welcome_index_path(Current.account)
    end
  end

  # GET /pipelines/1 or /pipelines/1.json (Inertia)
  def show
    filter_status_deal = params[:filter_status_deal].presence || 'open'
    account = Account.find(params[:account_id])
    @pipelines = Pipeline.all

    stages_data = @pipeline.stages.sort_by(&:position).map do |stage|
      deals_query = if filter_status_deal == 'all'
                      stage.deals.order(position: :desc)
                    else
                      stage.deals.where(status: filter_status_deal).order(position: :desc)
                    end

      pagy_result, deals = pagy(deals_query, items: 20)

      {
        id: stage.id,
        name: stage.name,
        position: stage.position,
        total_amount: stage.total_amount_deals(filter_status_deal),
        total_quantity: stage.total_quantity_deals(filter_status_deal),
        total_quantity_resume: stage.total_quantity_deals_resume(filter_status_deal),
        deals: deals.map { |deal| serialize_deal(deal) },
        has_more_deals: pagy_result.next.present?,
        next_page: pagy_result.next
      }
    end

    render inertia: 'accounts/pipelines/show', props: {
      pipeline: {
        id: @pipeline.id,
        name: @pipeline.name,
        stages: stages_data
      },
      pipelines: Pipeline.all.map { |p| { id: p.id, name: p.name } },
      filter_status_deal: filter_status_deal,
      account_id: account.id,
      account_currency: account.currency_code || 'USD',
      user_locale: current_user.language || 'en'
    }
  end

  def load_more_deals
    # Only allow partial Inertia requests
    unless request.headers['X-Inertia-Partial-Data'].present?
      return redirect_to account_pipeline_path(params[:account_id], params[:id])
    end

    @pipelines = Pipeline.all
    stage = Stage.find(params[:stage_id])
    filter_status_deal = params[:filter_status_deal].presence || 'open'
    page = (params[:page] || 1).to_i

    deals_query = if filter_status_deal == 'all'
                    stage.deals.order(position: :desc)
                  else
                    stage.deals.where(status: filter_status_deal).order(position: :desc)
                  end

    pagy_result, deals = pagy(deals_query, items: 20, page: page)

    stage_deals_data = {
      stage_id: stage.id,
      deals: deals.map { |deal| serialize_deal(deal) },
      has_more_deals: pagy_result.next.present?,
      next_page: pagy_result.next
    }

    render inertia: 'accounts/pipelines/show', props: {
      stage_deals: stage_deals_data
    }
  end

  def refresh_stage
    # Only allow partial Inertia requests
    unless request.headers['X-Inertia-Partial-Data'].present?
      return redirect_to account_pipeline_path(params[:account_id], params[:id])
    end

    @pipelines = Pipeline.all
    stage = Stage.find(params[:stage_id])
    filter_status_deal = params[:filter_status_deal].presence || 'open'
    # Load at least as many items as currently loaded in frontend
    current_count = (params[:current_count] || 8).to_i
    items_to_load = [current_count, 20].max

    deals_query = if filter_status_deal == 'all'
                    stage.deals.order(position: :desc)
                  else
                    stage.deals.where(status: filter_status_deal).order(position: :desc)
                  end

    total_count = deals_query.count
    deals = deals_query.limit(items_to_load)
    has_more = total_count > items_to_load
    next_page = has_more ? (items_to_load / 20) + 1 : nil

    stage_refresh_data = {
      id: stage.id,
      name: stage.name,
      position: stage.position,
      total_amount: stage.total_amount_deals(filter_status_deal),
      total_quantity: stage.total_quantity_deals(filter_status_deal),
      total_quantity_resume: stage.total_quantity_deals_resume(filter_status_deal),
      deals: deals.map { |deal| serialize_deal(deal) },
      has_more_deals: has_more,
      next_page: next_page
    }

    render inertia: 'accounts/pipelines/show', props: {
      stage_refresh: stage_refresh_data
    }
  end

  # GET /pipelines/new
  def new
    @pipeline = Pipeline.new
  end

  # GET /pipelines/1/edit
  def edit
    @stages = @pipeline.stages.order(:position)
  end

  # POST /pipelines/1/import_file
  def import_file
    @pipeline = Pipeline.find(params[:pipeline_id])

    uploaded_io = params[:import_file]

    csv_text = uploaded_io.read
    csv = CSV.parse(csv_text, headers: true)

    path_to_output_csv_file = "#{Rails.root}/tmp/deals-#{Time.current.to_i}.csv"
    line = 0
    CSV.open(path_to_output_csv_file, 'wb') do |csv_output|
      csv.each do |row|
        csv_output << row.to_h.keys + ['result'] if line == 0

        row_json = JsonCsv.csv_row_hash_to_hierarchical_json_hash(row, {})

        row_params = ActionController::Parameters.new(row_json).merge({ "stage_id": params[:stage_id] })

        deal = DealBuilder.new(current_user, row_params).perform

        csv_output << if deal.save
                        row.to_h.values + [I18n.t('activerecord.models.deal.import_file_success', deal_id: deal.id)]
                      else
                        row.to_h.values + [I18n.t('activerecord.models.deal.import_file_failed',
                                                  message_error: deal.errors.messages)]
                      end
        line += 1
      end
    end

    response.headers['Content-Type'] = 'text/csv'
    response.headers['Content-Disposition'] = 'attachment; filename=deals.csv'
    # flash[:notice] = 'Arquivo processado com sucesso.'
    send_file path_to_output_csv_file
    # redirect_to account_pipeline_path(current_user.id, @pipeline.id), notice: 'Arquivo processado com sucesso.'
  end

  # GET /pipelines/1/import
  def import
    @pipeline = Pipeline.find(params[:pipeline_id])
    @stage = Stage.find(params[:stage_id])

    respond_to do |format|
      format.turbo_stream
      format.html
      format.csv do
        path_to_output_csv_file = "#{Rails.root}/tmp/deals-#{Time.current.to_i}.csv"
        # headers = Deal.csv_header(Current.account)
        headers = ['name', 'contact_attributes.full_name', 'contact_attributes.phone']
        CSV.open(path_to_output_csv_file, 'w') do |csv|
          csv << headers
        end

        response.headers['Content-Type'] = 'text/csv'
        response.headers['Content-Disposition'] = 'attachment; filename=deals.csv'
        render file: path_to_output_csv_file
      end
    end
  end

  # GET /pipelines/1/export
  def export
    @deals = Deal.where(stage_id: params['stage_id'])

    path_to_output_csv_file = "#{Rails.root}/tmp/deals-#{Time.current.to_i}.csv"
    JsonCsv.create_csv_for_json_records(path_to_output_csv_file) do |csv_builder|
      @deals.each do |deal|
        json = JSON.parse(deal.to_json(include: :contacts))
        csv_builder.add(json)
      end
    end

    respond_to do |format|
      format.html
      format.csv do
        response.headers['Content-Type'] = 'text/csv'
        response.headers['Content-Disposition'] = 'attachment; filename=deals.csv'
        render file: path_to_output_csv_file
      end
    end
  end

  def bulk_action; end

  def new_bulk_action; end

  def create_bulk_action
    @deals = Deal.where(stage_id: params['event']['stage_id'], status: 'open')
    @stage = Stage.find(params['event']['stage_id'])
    if params['event']['send_now'] == 'true'
      time_start = DateTime.current
    elsif !params['event']['scheduled_at'].nil?
      time_start = params['event']['scheduled_at'].in_time_zone
    end
    @result = @deals.each_with_index do |deal, index|
      if params['event']['kind'] == 'chatwoot_message' || params['event']['kind'] == 'evolution_api_message'
        if params['event']['send_now'] == 'true'
          time_start += rand(10..15).seconds
          params['event']['send_now'] = 'false'
        elsif !time_start.nil?
          time_start += rand(10..15).seconds
        end
      end
      @event = EventBuilder.new(current_user,
                                event_params.merge({ contact: deal.contact, scheduled_at: time_start })).build
      @event.deal = deal

      if !@event.valid? && index == 0
        render :new_bulk_action, status: :unprocessable_entity
        return
      end
      @event.save
    end
    respond_to do |format|
      format.turbo_stream
    end
  end

  def bulk_action_2; end

  # POST /pipelines or /pipelines.json
  def create
    @pipeline = Pipeline.new(pipeline_params)

    respond_to do |format|
      if @pipeline.save
        format.html do
          redirect_to account_pipeline_path(Current.account, @pipeline),
                      notice: t('flash_messages.created', model: Pipeline.model_name.human)
        end
        format.json { render :show, status: :created, location: @pipeline }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @pipeline.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /pipelines/1 or /pipelines/1.json
  def update
    if @pipeline.update(pipeline_params)
      respond_to do |format|
        format.html do
          redirect_to account_pipeline_path(Current.account, @pipeline),
                      notice: t('flash_messages.updated', model: Pipeline.model_name.human)
        end
        format.turbo_stream
      end
    end
  end

  # DELETE /pipelines/1 or /pipelines/1.json
  def destroy
    @pipeline.destroy
    respond_to do |format|
      format.html { redirect_to pipelines_url, notice: t('flash_messages.deleted', model: Pipeline.model_name.human) }
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_pipeline
    @pipeline = Pipeline.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def pipeline_params
    params.require(:pipeline).permit(:name, stages_attributes: %i[id name _destroy account_id position])
  end

  def set_bulk_action_event
    @event = EventBuilder.new(current_user,
                              { kind: params[:kind] }).build
  end

  def set_stage
    @stage = Stage.find(params[:stage_id])
  end

  def deal_params(params)
    params.permit(
      :name, :status, :stage_id, :contact_id,
      contact_attributes: %i[id full_name phone email],
      custom_attributes: {}
    )
  end

  def event_params
    params.require(:event).permit(:content, :send_now, :done, :auto_done, :title, :kind, :app_type, :app_id, :from_me, files: [],
                                                                                                                       custom_attributes: {}, additional_attributes: {})
  rescue StandardError
    {}
  end

  def serialize_deal(deal)
    {
      id: deal.id,
      name: deal.name,
      status: deal.status,
      position: deal.position,
      total_amount_in_cents: deal.total_amount_in_cents,
      contact: {
        id: deal.contact.id,
        full_name: deal.contact.full_name
      },
      users: deal.users.order(id: :desc).limit(3).map do |user|
        {
          id: user.id,
          full_name: user.full_name,
          avatar_url: user.avatar_url
        }
      end,
      users_count: deal.users.count,
      next_event_planned: deal.next_event_planned ? {
        id: deal.next_event_planned.id,
        primary_date: deal.next_event_planned.primary_date.to_s,
        overdue: deal.next_event_planned.overdue?
      } : nil
    }
  end
end
