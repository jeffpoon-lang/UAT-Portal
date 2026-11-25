# 登入咗嘅人自己改密碼。改完之後其他裝置要重新登入，而家呢個唔使。
class PasswordChangesController < ApplicationController
  layout -> { Current.user.role_admin? ? "admin" : "portal" }
  rate_limit to: 10, within: 3.minutes, only: :update,
             with: -> { redirect_to edit_password_change_path, alert: "試得太多次，請過幾分鐘再試" }

  def edit; end

  def update
    current, password, confirmation = params.expect(password_change: [ :current_password, :password, :password_confirmation ])
                                            .values_at(:current_password, :password, :password_confirmation)
    user = Current.user

    @error =
      if !user.authenticate(current.to_s) then "現有密碼唔啱"
      elsif password.to_s.length < User::MIN_PASSWORD_LENGTH then "新密碼最少要 #{User::MIN_PASSWORD_LENGTH} 個字"
      elsif password != confirmation then "兩次輸入嘅新密碼唔一樣"
      end
    return render(:edit, status: :unprocessable_entity) if @error

    user.update!(password: password)
    user.sessions.where.not(id: Current.session.id).destroy_all
    redirect_to root_path, notice: "密碼已經更新"
  end
end
