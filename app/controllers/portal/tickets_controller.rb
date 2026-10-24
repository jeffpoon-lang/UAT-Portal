class Portal::TicketsController < Portal::BaseController
  before_action :set_project

  def new
    return redirect_to(portal_project_path(@project), alert: "Project 上線之後先可以開 ticket") unless @project.accepts_tickets?

    @ticket = @project.tickets.build(priority: :normal)
  end

  def create
    @ticket = @project.tickets.build(ticket_params.merge(opened_by: Current.user))
    if @ticket.save
      redirect_to portal_project_ticket_path(@project, @ticket), notice: "已開 #{@ticket.doc_number}，處理之後會喺度更新"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @ticket = @project.tickets.find(params[:id])
  end

  private
    def set_project = @project = project_scope.find(params[:project_id])

    def ticket_params
      attrs = params.expect(ticket: [ :title, :body, :priority, screenshots: [] ])
      attrs[:screenshots] = Array(attrs[:screenshots]).compact_blank if attrs.key?(:screenshots)
      attrs
    end
end
