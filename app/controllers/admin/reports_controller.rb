class Admin::ReportsController < Admin::BaseController
  def maintenance
    @clients = Client.order(:name)
    @client = params[:client_id].present? ? Client.find(params[:client_id]) : @clients.first
    @month = parse_month(params[:month]) || Date.current.beginning_of_month
    @report = MaintenanceReport.new(client: @client, month: @month) if @client
  end

  private
    def parse_month(value)
      Date.strptime(value.to_s, "%Y-%m") if value.to_s.match?(/\A\d{4}-\d{2}\z/)
    rescue Date::Error
      nil
    end
end
