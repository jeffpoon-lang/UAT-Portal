class Admin::ClientsController < Admin::BaseController
  before_action :set_client, only: %i[show edit update]

  def index
    @clients = Client.order(:name)
  end

  def show
    @projects = @client.projects.order(updated_at: :desc)
  end

  def new
    @client = Client.new
  end

  def create
    @client = Client.new(client_params)
    if @client.save
      redirect_to admin_client_path(@client), notice: "已新增客戶 #{@client.name}"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @client.update(client_params)
      redirect_to admin_client_path(@client), notice: "已更新"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private
    def set_client = @client = Client.find(params[:id])
    def client_params = params.expect(client: [ :name, :code, :contact_email ])
end
