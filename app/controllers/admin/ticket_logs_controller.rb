class Admin::TicketLogsController < Admin::BaseController
  def create
    @ticket = Ticket.find(params[:ticket_id])
    @log = @ticket.logs.build(params.expect(ticket_log: [ :logged_on, :minutes, :note ]).merge(user: Current.user))

    if @log.save
      # 有記錄就代表開始處理
      @ticket.update!(status: :in_progress) if @ticket.status_open?
      redirect_to admin_ticket_path(@ticket), notice: "已記錄 #{@log.minutes} 分鐘"
    else
      render "admin/tickets/show", status: :unprocessable_entity
    end
  end
end
