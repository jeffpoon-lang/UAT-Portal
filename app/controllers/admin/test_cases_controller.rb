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

  def destroy
    @test_case.destroy
    redirect_to admin_project_path(@project), notice: "已刪除 #{@test_case.code}", status: :see_other
  end

  private
    def set_project = @project = Project.find(params[:project_id])
    def set_test_case = @test_case = @project.test_cases.find(params[:id])
    def test_case_params = params.expect(test_case: [ :code, :title, :steps, :expected, :source ])
end
