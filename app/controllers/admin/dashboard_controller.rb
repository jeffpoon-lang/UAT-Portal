class Admin::DashboardController < Admin::BaseController
  def show
    @projects = Project.includes(:client).order(updated_at: :desc)
    @counts = Project.group(:phase).count
    # 等緊你做嘢：未批嘅 CR，同客交咗要修正、仲未開下一輪嘅 round
    @pending_crs = ChangeRequest.status_pending.includes(project: :client).order(:created_at)
    @rounds_to_fix = UatRound.status_changes_requested.includes(project: [ :client, :uat_rounds ]).order(:closed_at)
                             .select { |r| r.project.latest_round == r }
  end
end
