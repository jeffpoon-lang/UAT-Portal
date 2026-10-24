# Production：唔落 demo data。有齊 ADMIN_EMAIL 同 ADMIN_PASSWORD 先建 admin，冇就乜都唔做。
if Rails.env.production?
  if ENV["ADMIN_EMAIL"].present? && ENV["ADMIN_PASSWORD"].present?
    User.find_or_create_by!(email_address: ENV["ADMIN_EMAIL"]) do |u|
      u.password = ENV["ADMIN_PASSWORD"]
      u.role = :admin
    end
    puts "Production admin ready"
  else
    puts "Production：未設 ADMIN_EMAIL／ADMIN_PASSWORD，冇建任何帳號"
  end
  return
end

# 以下 demo data 只作開發用。登入資料可以用環境變數改：
#   ADMIN_EMAIL / ADMIN_PASSWORD / CLIENT_PASSWORD
admin_email = ENV.fetch("ADMIN_EMAIL", "admin@example.com")
admin_pw    = ENV.fetch("ADMIN_PASSWORD", "demo-admin-2026")
client_pw   = ENV.fetch("CLIENT_PASSWORD", "demo-client-2026")

User.find_or_create_by!(email_address: admin_email) do |u|
  u.password = admin_pw
  u.role = :admin
end

yoga = Client.find_or_create_by!(code: "DEMOYOGA") do |c|
  c.name = "Demo Yoga Studio"
  c.contact_email = "hello@demoyoga.example"
end

User.find_or_create_by!(email_address: "client@demoyoga.example") do |u|
  u.password = client_pw
  u.role = :client
  u.client = yoga
end

course = yoga.projects.find_or_create_by!(name: "網上課程 + Landing page") do |p|
  p.phase = :uat
  p.max_uat_rounds = 3
end

[
  [ "訪客由 landing page 撳「立即報名」", "去到 checkout 頁，價錢顯示正確" ],
  [ "用 Stripe 測試卡付款", "付款成功，收到確認 email" ],
  [ "付款後登入課程", "見到第一課，影片播放到" ],
  [ "手機版瀏覽 landing page", "版面冇爆，按鈕撳到" ]
].each_with_index do |(title, expected), i|
  course.test_cases.find_or_create_by!(code: format("TC-%02d", i + 1)) do |tc|
    tc.title = title
    tc.expected = expected
    tc.source = :client
  end
end

yoga.projects.find_or_create_by!(name: "Booking system") { |p| p.phase = :development }

# 開好 Round 1，客戶一登入就可以試 UAT 流程
course.open_next_round! if course.uat_rounds.empty?

puts "Seeded: #{User.count} users, #{Client.count} clients, #{Project.count} projects, #{TestCase.count} test cases, #{UatRound.count} UAT rounds"
