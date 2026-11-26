# 系統資料：網址、帳戶喺邊個名下。客戶喺 portal 睇到
class Admin::SystemLinksController < Admin::BaseController
  before_action :set_project
  before_action :set_link, only: %i[edit update destroy]

  def new
    @link = @project.system_links.build(kind: params[:kind].presence_in(SystemLink::KINDS) || "site",
                                        position: @project.system_links.size + 1)
  end

  def create
    @link = @project.system_links.build(link_params)
    if @link.save
      redirect_to admin_project_path(@project, anchor: "system-links"), notice: "已加「#{@link.label}」"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @link.update(link_params)
      redirect_to admin_project_path(@project, anchor: "system-links"), notice: "已更新「#{@link.label}」"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @link.destroy
    redirect_to admin_project_path(@project, anchor: "system-links"), notice: "已刪除「#{@link.label}」", status: :see_other
  end

  private
    def set_project = @project = Project.find(params[:project_id])
    def set_link = @link = @project.system_links.find(params[:id])
    def link_params = params.expect(system_link: [ :kind, :position, :label, :url, :account_owner, :note ])
end
