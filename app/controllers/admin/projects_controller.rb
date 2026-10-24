class Admin::ProjectsController < Admin::BaseController
  before_action :set_project, only: %i[show edit update]

  def index
    @projects = Project.includes(:client).order(updated_at: :desc)
  end

  def show; end

  def new
    @project = Project.new(client_id: params[:client_id])
  end

  def create
    @project = Project.new(project_params)
    if @project.save
      redirect_to admin_project_path(@project), notice: "已建立 project"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @project.update(project_params)
      redirect_to admin_project_path(@project), notice: "已更新"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private
    def set_project = @project = Project.find(params[:id])
    def project_params = params.expect(project: [ :client_id, :name, :phase, :max_uat_rounds, :maintenance_start_on ])
end
