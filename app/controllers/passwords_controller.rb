class PasswordsController < ApplicationController
  layout "auth"
  allow_unauthenticated_access
  before_action :set_user_by_token, only: %i[ edit update ]
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to new_password_path, alert: "試得太多次，請過幾分鐘再試" }

  def new
  end

  def create
    if user = User.find_by(email_address: params[:email_address])
      PasswordsMailer.reset(user).deliver_later
    end

    redirect_to new_session_path, notice: "如果呢個電郵有帳戶，我哋已經寄咗重設指示"
  end

  def edit
  end

  def update
    if @user.update(params.permit(:password, :password_confirmation))
      @user.sessions.destroy_all
      redirect_to new_session_path, notice: "密碼已經更新，請重新登入"
    else
      alert = @user.errors.include?(:password_confirmation) ? "兩次輸入嘅密碼唔一樣" : "新密碼最少要 #{User::MIN_PASSWORD_LENGTH} 個字"
      redirect_to edit_password_path(params[:token]), alert: alert
    end
  end

  private
    def set_user_by_token
      @user = User.find_by_password_reset_token!(params[:token])
    rescue ActiveSupport::MessageVerifier::InvalidSignature
      redirect_to new_password_path, alert: "重設連結無效或者已經過期"
    end
end
