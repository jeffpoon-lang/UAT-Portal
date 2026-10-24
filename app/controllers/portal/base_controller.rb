# 客戶只可以掂自己公司嘅 project；admin 都入得嚟睇
class Portal::BaseController < ApplicationController
  private
    def project_scope
      Current.user.role_admin? ? Project.all : Project.where(client_id: Current.user.client_id)
    end
end
