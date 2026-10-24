class Portal::TestResultsController < Portal::BaseController
  def update
    @project = project_scope.find(params[:project_id])
    @round = @project.uat_rounds.find(params[:uat_round_id])
    @result = @round.test_results.find(params[:id])

    attrs = params.expect(test_result: [ :status, :comment, screenshots: [] ])
    new_shots = Array(attrs.delete(:screenshots)).compact_blank
    # 新截圖加喺舊截圖後面（直接 assign 會覆蓋晒舊嘅），save 嗰陣先一齊寫入
    attrs[:screenshots] = @result.screenshots.blobs.to_a + new_shots if new_shots.any?
    @result.assign_attributes(attrs)

    saved = @result.save
    @round.test_results.reset

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.replace(helpers.dom_id(@result), partial: "portal/test_results/result", locals: { result: @result, saved: saved }),
          turbo_stream.update("round-counts", partial: "shared/round_counts", locals: { round: @round }),
          turbo_stream.replace("round-submit", partial: "portal/uat_rounds/submit", locals: { round: @round, project: @project })
        ], status: saved ? :ok : :unprocessable_entity
      end
      format.html do
        if saved
          redirect_to portal_project_uat_round_path(@project, @round), notice: "已儲存 #{@result.test_case.code}"
        else
          redirect_to portal_project_uat_round_path(@project, @round), alert: @result.errors.full_messages.to_sentence
        end
      end
    end
  end
end
