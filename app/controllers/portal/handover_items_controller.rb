class Portal::HandoverItemsController < Portal::BaseController
  def update
    item = HandoverItem.joins(:retainer_plan).where(retainer_plans: { client_id: Current.user.client_id }).find(params[:id])
    return head(:forbidden) unless item.editable_by?(Current.user)

    item.mark!(done: params[:done] == "1", user: Current.user)
    redirect_to portal_retainer_path, notice: "已更新交接清單"
  end
end
