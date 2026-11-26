class Admin::ReportsController < Admin::BaseController
  def maintenance
    @clients = Client.order(:name)
    @client = params[:client_id].present? ? Client.find(params[:client_id]) : @clients.first
    @month = MaintenanceReport.parse_month(params[:month]) || Date.current.beginning_of_month
    @report = MaintenanceReport.new(client: @client, month: @month) if @client
  end
end
