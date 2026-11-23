class PasswordsMailer < ApplicationMailer
  def reset(user)
    @user = user
    mail subject: "重設 UAT Portal 密碼", to: user.email_address
  end
end
