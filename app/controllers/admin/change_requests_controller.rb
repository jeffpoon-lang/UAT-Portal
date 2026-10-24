class Admin::ChangeRequestsController < Admin::BaseController
  before_action :set_project

  def new
    @change_request = @project.change_requests.build(extra_rounds: 1)
  end

  def create
    @change_request = @project.change_requests.build(change_request_params)
    if @change_request.save
      redirect_to admin_project_path(@project), notice: "已開 #{@change_request.doc_number}，客戶簽咗之後記得撳批核"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def approve = decide(:approved, "已批核")
  def reject = decide(:rejected, "已拒絕")

  private
    def set_project = @project = Project.find(params[:project_id])
    def change_request_params = params.expect(change_request: [ :description, :extra_rounds, :quote_hkd ])

    def decide(status, label)
      cr = @project.change_requests.find(params[:id])
      return redirect_to(admin_project_path(@project), alert: "#{cr.doc_number} 已經處理咗") unless cr.status_pending?

      cr.update!(status: status)
      redirect_to admin_project_path(@project), notice: "#{label} #{cr.doc_number}"
    end
end
