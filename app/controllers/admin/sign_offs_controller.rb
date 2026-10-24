class Admin::SignOffsController < Admin::BaseController
  def index
    @sign_offs = SignOff.includes(project: :client).order(id: :desc)
  end

  def show
    @sign_off = SignOff.find(params[:id])
  end

  # 用 Rust 由第一條 sign-off 驗到最後一條
  def verify
    result = SignOff.verify_chain
    if result.ok?
      redirect_to admin_sign_offs_path, notice: "驗證通過：#{result.count} 條 sign-off 全部完整，冇被改過。"
    else
      broken = SignOff.order(:id).offset(result.broken_index - 1).first
      reason = { "digest_mismatch" => "內容同 digest 對唔上（內容被改過）",
                 "prev_mismatch" => "同上一條接唔上（有記錄被刪除、調亂或者重新計過）",
                 "format_error" => "記錄格式錯誤" }.fetch(result.reason, result.reason)
      redirect_to admin_sign_offs_path, alert: "驗證失敗：第 #{result.broken_index} 條（#{broken&.doc_number}）#{reason}。"
    end
  rescue SealService::Error => e
    redirect_to admin_sign_offs_path, alert: "驗證工具出錯：#{e.message}"
  end
end
