class Portal::SignOffsController < Portal::BaseController
  def show
    @sign_off = SignOff.where(project: project_scope).find(params[:id])
  end
end
