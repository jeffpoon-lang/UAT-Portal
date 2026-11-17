class Admin::HandoverItemsController < Admin::BaseController
  def update
    item = HandoverItem.find(params[:id])
    item.mark!(done: params[:done] == "1", user: Current.user)
    redirect_to admin_client_path(item.retainer_plan.client), notice: "已更新交接清單"
  end
end
