class Portal::UatRoundsController < Portal::BaseController
  before_action :set_round

  def show; end

  # 有 test case fail：交返畀 IT 改
  def request_changes
    @round.request_changes!
    redirect_to portal_project_path(@project), notice: "已提交 Round #{@round.number} 結果，IT 修正之後會開下一個 round。"
  rescue UatRound::NotAllowed => e
    redirect_to portal_project_uat_round_path(@project, @round), alert: e.message
  end

  # 全部 pass：客簽署
  def sign_off
    return head(:forbidden) unless Current.user.role_client?
    unless params[:confirm] == "1"
      return redirect_to(portal_project_uat_round_path(@project, @round), alert: "請剔選確認聲明")
    end

    sign_off = SignOff.sign!(round: @round, user: Current.user, signer_name: params[:signer_name])
    redirect_to portal_sign_off_path(sign_off), notice: "已完成 UAT sign-off（#{sign_off.doc_number}）"
  rescue UatRound::NotAllowed => e
    redirect_to portal_project_uat_round_path(@project, @round), alert: e.message
  end

  private
    def set_round
      @project = project_scope.find(params[:project_id])
      @round = @project.uat_rounds.find(params[:id])
    end
end
