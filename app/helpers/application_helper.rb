module ApplicationHelper
  def hkd(amount) = "HK$#{number_with_delimiter(amount.to_i)}"
end
