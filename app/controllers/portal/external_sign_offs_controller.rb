# 客戶下載自己 project 嘅簽署文件
class Portal::ExternalSignOffsController < Portal::BaseController
  include SendsDocument

  def document
    project = project_scope.find(params[:project_id])
    send_document(project.external_sign_offs.find(params[:id]).document)
  end
end
