# 登入後按角色分流：你去後台，客去 portal
class HomeController < ApplicationController
  def show
    redirect_to Current.user.role_admin? ? admin_root_path : portal_projects_path
  end
end
