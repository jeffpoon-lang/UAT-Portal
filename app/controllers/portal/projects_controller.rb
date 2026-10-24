# 客戶只睇到自己公司嘅 project
class Portal::ProjectsController < ApplicationController
  def index
    @projects = scope.order(updated_at: :desc)
  end

  def show
    @project = scope.find(params[:id])
  end

  private
    def scope
      Current.user.role_admin? ? Project.all : Project.where(client_id: Current.user.client_id)
    end
end
