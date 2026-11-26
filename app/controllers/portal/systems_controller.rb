# 客戶睇自己系統嘅網址、帳戶同支援資料
class Portal::SystemsController < Portal::BaseController
  def show
    @project = project_scope.find(params[:project_id])
    @groups = SystemLink.grouped(@project.system_links)
  end
end
