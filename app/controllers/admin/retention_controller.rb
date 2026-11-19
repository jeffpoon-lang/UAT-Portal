class Admin::RetentionController < Admin::BaseController
  def show
    @today = Date.current
    @rows = RetentionRow.all(today: @today).sort_by { |r| RetentionRow::SIGNALS.keys.index(r.signal) }
    @mrr = RetentionRow.monthly_recurring_hkd(today: @today)
  end
end
