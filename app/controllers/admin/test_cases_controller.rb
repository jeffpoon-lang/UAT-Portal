class Admin::TestCasesController < Admin::BaseController
  before_action :set_project
  before_action :set_test_case, only: %i[edit update destroy]

  def new
    @test_case = @project.test_cases.build(code: @project.next_test_case_code)
  end

  def create
    @test_case = @project.test_cases.build(test_case_params)
    if @test_case.save
      redirect_to admin_project_path(@project), notice: "已加 #{@test_case.code}"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @test_case.update(test_case_params)
      redirect_to admin_project_path(@project), notice: "已更新 #{@test_case.code}"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # 將未記錄 IT 結果嘅 test case 一次過記做「IT 已測通過」（今日）
  def mark_it_passed
    count = @project.mark_untested_cases_it_passed!
    notice = count.zero? ? "冇未記錄嘅 test case，冇嘢改" : "已將 #{count} 條記做 IT 已測通過"
    redirect_to admin_project_path(@project), notice: notice, status: :see_other
  end

  def destroy
    @test_case.destroy
    redirect_to admin_project_path(@project), notice: "已刪除 #{@test_case.code}", status: :see_other
  end

  private
    def set_project = @project = Project.find(params[:project_id])
    def set_test_case = @test_case = @project.test_cases.find(params[:id])
    def test_case_params = params.expect(test_case: [ :code, :title, :steps, :expected, :source, :it_status, :it_tested_on, :it_note ])
end
