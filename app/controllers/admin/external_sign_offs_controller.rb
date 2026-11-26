# 記錄喺 portal 以外簽咗嘅 UAT 聲明，附簽咗嘅 PDF
class Admin::ExternalSignOffsController < Admin::BaseController
  include SendsDocument

  before_action :set_project
  before_action :set_sign_off, only: %i[edit update destroy document]

  def new
    @sign_off = @project.external_sign_offs.build(position: @project.external_sign_offs.size + 1)
  end

  def create
    @sign_off = @project.external_sign_offs.build(sign_off_params)
    if @sign_off.save
      redirect_to admin_project_path(@project, anchor: "external-sign-offs"), notice: "已加簽署記錄「#{@sign_off.title}」"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @sign_off.update(sign_off_params)
      redirect_to admin_project_path(@project, anchor: "external-sign-offs"), notice: "已更新「#{@sign_off.title}」"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @sign_off.destroy
    redirect_to admin_project_path(@project, anchor: "external-sign-offs"), notice: "已刪除「#{@sign_off.title}」", status: :see_other
  end

  def document = send_document(@sign_off.document)

  private
    def set_project = @project = Project.find(params[:project_id])
    def set_sign_off = @sign_off = @project.external_sign_offs.find(params[:id])

    def sign_off_params
      params.expect(external_sign_off: [ :position, :scope, :title, :statement, :signer_name, :signed_on,
                                         :countersigned_by, :final, :note, :document ])
    end
end
