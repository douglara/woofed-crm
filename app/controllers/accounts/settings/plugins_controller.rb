class Accounts::Settings::PluginsController < Inertia::InternalController
  layout 'inertia_overlay'

  before_action :set_plugin, only: %i[show destroy]

  def index
    plugins = Current.account.plugins.order(created_at: :desc)
    render inertia: 'Accounts/Settings/Plugins/Index', props: {
      plugins: plugins.map { |p| serialize_plugin(p) }
    }
  end

  def new
    render inertia: 'Accounts/Settings/Plugins/New'
  end

  def create
    plugin = Plugin.new(plugin_params.merge(account: Current.account))
    if plugin.save
      redirect_to account_settings_plugin_path(Current.account, plugin)
    else
      render inertia: 'Accounts/Settings/Plugins/New', props: {
        errors: plugin.errors.as_json(full_messages: true),
        values: plugin_params
      }
    end
  end

  def show
    render inertia: 'Accounts/Settings/Plugins/Show', props: {
      plugin: serialize_plugin(@plugin)
    }
  end

  def destroy
    @plugin.destroy
    # Full redirect back to Hotwire settings page (exits the Inertia overlay)
    redirect_to account_settings_path(Current.account), status: :see_other
  end

  private

  def set_plugin
    @plugin = Current.account.plugins.find(params[:id])
  end

  def plugin_params
    params.require(:plugin).permit(:name, :description, :prompt)
  end

  def serialize_plugin(plugin)
    {
      id: plugin.id,
      name: plugin.name,
      description: plugin.description,
      prompt: plugin.prompt,
      status: plugin.status,
      created_at: plugin.created_at,
      updated_at: plugin.updated_at
    }
  end
end
