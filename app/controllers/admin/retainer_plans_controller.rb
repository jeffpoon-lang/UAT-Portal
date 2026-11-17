class Admin::RetainerPlansController < Admin::BaseController
  before_action :set_client
  before_action :set_plan, except: %i[new create]

  def new
    @plan = @client.build_retainer_plan(starts_on: Date.current.beginning_of_month)
  end

  def create
    @plan = @client.build_retainer_plan(plan_params)
    if @plan.save
      redirect_to admin_client_path(@client), notice: "已設定 retainer"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @plan.update(plan_params)
      redirect_to admin_client_path(@client), notice: "已更新 retainer"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def give_notice
    by = params[:notice_given_by].to_s
    return redirect_to(admin_client_path(@client), alert: "請揀邊方通知終止") unless RetainerPlan.notice_given_bies.key?(by)

    on = Date.iso8601(params[:notice_given_on].presence || Date.current.iso8601)
    @plan.give_notice!(by: by, on: on)
    redirect_to admin_client_path(@client), notice: "已記錄通知終止，合約 #{@plan.ends_on} 完結，交接清單已列出"
  rescue Date::Error
    redirect_to admin_client_path(@client), alert: "日期格式唔啱"
  end

  def withdraw_notice
    @plan.withdraw_notice!
    redirect_to admin_client_path(@client), notice: "已撤回通知終止"
  end

  private
    def set_client = @client = Client.find(params[:client_id])

    def set_plan
      @plan = @client.retainer_plan
      redirect_to new_admin_client_retainer_plan_path(@client), alert: "未設定 retainer" unless @plan
    end

    def plan_params
      params.expect(retainer_plan: [ :monthly_fee_hkd, :included_rounds, :extra_round_hkd, :starts_on, :notice_days, :quote_ref ])
    end
end
