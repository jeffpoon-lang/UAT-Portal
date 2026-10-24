class Admin::DashboardController < Admin::BaseController
  def show
    @projects = Project.includes(:client).order(updated_at: :desc)
    @counts = Project.group(:phase).count
  end
end
