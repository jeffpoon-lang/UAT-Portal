class Portal::ProjectsController < Portal::BaseController
  def index
    @projects = project_scope.order(updated_at: :desc)
  end

  def show
    @project = project_scope.find(params[:id])
  end
end
