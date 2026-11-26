# 客戶自己揀月份睇 maintenance 月報（同 admin 月尾報告同一份內容）。
# Admin 可以帶 client_id 預覽客戶睇到嘅版本。
class Portal::ReportsController < Portal::BaseController
  MAX_MONTHS = 24

  def show
    @client = report_client
    return redirect_to(portal_projects_path, alert: "未有月報") unless @client&.has_monthly_reports?

    @months = available_months(@client)
    @month = MaintenanceReport.parse_month(params[:month])
    @month = @months.first unless @months.include?(@month)
    @report = MaintenanceReport.new(client: @client, month: @month)
  end

  private
    def report_client
      Current.user.role_admin? ? Client.find_by(id: params[:client_id]) : Current.user.client
    end

    # 由 maintenance 開始（或者第一張 ticket）嗰個月到今個月，新嘅排先
    def available_months(client)
      current = Date.current.beginning_of_month
      starts = [ client.retainer_plan&.starts_on, client.projects.minimum(:maintenance_start_on),
                 client.tickets.minimum(:created_at)&.to_date ].compact.min
      first = (starts || current).beginning_of_month.clamp(current << (MAX_MONTHS - 1), current)
      (0...MAX_MONTHS).map { |i| current << i }.select { |m| m >= first }
    end
end
