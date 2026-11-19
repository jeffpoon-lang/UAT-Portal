# 月尾報告上嘅「本月完成／下月建議」：同一客戶同一個月只得一份，再儲就覆蓋
class Admin::MonthlyUpdatesController < Admin::BaseController
  def create
    attrs = params.expect(monthly_update: [ :client_id, :month, :done_summary, :next_steps ])
    client = Client.find(attrs[:client_id])
    month = Date.strptime(attrs[:month].to_s, "%Y-%m")
    update = MonthlyUpdate.find_or_initialize_by(client: client, month: month.beginning_of_month)
    update.update!(done_summary: attrs[:done_summary], next_steps: attrs[:next_steps])
    redirect_to admin_maintenance_report_path(client_id: client.id, month: month.strftime("%Y-%m")), notice: "已儲存進度更新"
  rescue Date::Error
    redirect_to admin_maintenance_report_path, alert: "月份格式唔啱"
  end
end
