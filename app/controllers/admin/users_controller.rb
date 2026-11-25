# 客戶嘅登入帳戶：開帳戶、重設密碼、刪除。
# 密碼由系統產生，只喺回應頁顯示一次（唔入 flash、唔入 log、唔 cache）。
class Admin::UsersController < Admin::BaseController
  before_action :set_client, only: %i[new create]
  before_action :set_user, only: %i[destroy reset_password]

  def new
    @user = @client.users.build(email_address: (@client.contact_email unless User.exists?(email_address: @client.contact_email)))
  end

  def create
    password = User.generate_password
    @user = @client.users.build(email_address: params.expect(user: [ :email_address ])[:email_address], role: :client, password: password)
    if @user.save
      show_credentials(password, created: true)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def reset_password
    password = User.generate_password
    @user.update!(password: password)
    @user.sessions.destroy_all
    show_credentials(password, created: false)
  end

  def destroy
    @user.destroy!
    redirect_to admin_client_path(@user.client), notice: "已刪除 #{@user.email_address} 嘅登入帳戶", status: :see_other
  end

  private
    def set_client
      @client = Client.find(params[:client_id])
    end

    # 只可以管理客戶帳戶，admin 帳戶唔經呢度
    def set_user
      @user = User.role_client.find(params[:id])
    end

    def show_credentials(password, created:)
      response.headers["Cache-Control"] = "no-store"
      render :credentials, locals: { user: @user, client: @user.client, password: password, created: created }
    end
end
