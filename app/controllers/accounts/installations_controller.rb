class Accounts::InstallationsController < InternalController
  layout 'devise', only: %i[step_1 step_2 step_3]
  layout 'installations_loading', only: %i[loading]

  def step_1
  end

  def step_2
  end

  def step_3
  end

  def loading
  end
end
