class Admin::TicketsController < Admin::BaseController
  FILTERS = { "unresolved" => "未解決", "resolved" => "已解決", "all" => "全部" }.freeze

  def index
    @filter = FILTERS.key?(params[:filter]) ? params[:filter] : "unresolved"
    scope = Ticket.includes(project: :client).order(priority: :desc, created_at: :asc)
    @tickets = case @filter
    when "unresolved" then scope.unresolved
    when "resolved" then scope.status_resolved.reorder(resolved_at: :desc)
    else scope
    end
  end

  def show
    @ticket = Ticket.find(params[:id])
    @log = @ticket.logs.build(logged_on: Date.current, minutes: 30)
  end

  def update
    @ticket = Ticket.find(params[:id])
    if @ticket.update(params.expect(ticket: [ :status, :priority ]))
      redirect_to admin_ticket_path(@ticket), notice: "已更新：#{@ticket.status_label}"
    else
      redirect_to admin_ticket_path(@ticket), alert: @ticket.errors.full_messages.to_sentence
    end
  end
end
