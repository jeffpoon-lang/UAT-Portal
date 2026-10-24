class Admin::UatRoundsController < Admin::BaseController
  before_action :set_project

  def create
    round = @project.open_next_round!
    redirect_to admin_project_uat_round_path(@project, round), notice: "已開 Round #{round.number}，客戶可以開始測試"
  rescue UatRound::NotAllowed => e
    redirect_to admin_project_path(@project), alert: e.message
  end

  def show
    @round = @project.uat_rounds.find(params[:id])
  end

  def summarise
    round = @project.uat_rounds.find(params[:id])
    AiSummaryService.call(round)
    redirect_to admin_project_uat_round_path(@project, round), notice: "AI 摘要已更新"
  rescue AiSummaryService::Error => e
    redirect_to admin_project_uat_round_path(@project, round), alert: "AI 摘要失敗：#{e.message}"
  end

  private
    def set_project = @project = Project.find(params[:project_id])
end
