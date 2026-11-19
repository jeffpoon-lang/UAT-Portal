# 客戶睇自己嘅 retainer：本月用量、通知終止狀態、交接清單
class Portal::RetainersController < Portal::BaseController
  def show
    @plan = Current.user.client&.retainer_plan
    return redirect_to(portal_projects_path, alert: "未有月費維護合約") unless @plan

    @today = Date.current
  end
end
