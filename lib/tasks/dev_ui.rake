# Extra demo data for checking the UI in every state the seeds don't cover:
# a client without a retainer, a failed round with a screenshot, a pending CR,
# a signed-off project, a retainer under notice and a used-up month.
#
#   bin/rails db:seed:replant dev:ui_states
#
# Development only. The sign-off needs the Rust seal binary (bin/build-seal).
namespace :dev do
  desc "Add demo data that shows every UI state (development only)"
  task ui_states: :environment do
    abort "dev:ui_states only runs in development" unless Rails.env.development?

    password = ENV.fetch("CLIENT_PASSWORD", "demo-client-2026")
    admin = User.find_by!(role: :admin)
    screenshot = Rails.root.join("test/fixtures/files/screenshot.png")

    # A client in UAT with a failed round, a pending CR and no retainer
    cafe = Client.find_or_create_by!(code: "DEMOCAFE") do |c|
      c.name = "Demo Café"
      c.contact_email = "hello@democafe.example"
    end
    cafe_user = User.find_or_create_by!(email_address: "client@democafe.example") do |u|
      u.password = password
      u.role = :client
      u.client = cafe
    end

    app = cafe.projects.find_or_create_by!(name: "會員 App") do |p|
      p.phase = :uat
      p.max_uat_rounds = 2
    end
    if app.test_cases.empty?
      [
        [ "新會員用電話號碼註冊", "收到 SMS 驗證碼，註冊成功" ],
        [ "掃 QR code 儲印花", "印花數即時加一" ],
        [ "集滿 10 個印花換飲品", "顯示換領碼，印花歸零" ]
      ].each_with_index do |(title, expected), i|
        app.test_cases.create!(code: format("TC-%02d", i + 1), title: title, expected: expected,
                               steps: "用 iPhone 同 Android 各試一次", source: :client)
      end
    end
    if app.uat_rounds.empty?
      round = app.open_next_round!
      first, second, third = round.test_results.to_a
      first.update!(status: :pass)
      second.update!(status: :fail, comment: "Android 掃完 QR code 冇反應，要重新開 app 先見到印花")
      second.screenshots.attach(io: File.open(screenshot), filename: "android-qr.png")
      third.update!(status: :blocked, comment: "未有 10 個印花嘅測試帳戶，試唔到")
      round.reload.request_changes!

      round2 = app.open_next_round!
      round2.test_results.first.update!(status: :pass)
    end
    app.change_requests.find_or_create_by!(description: "加 Apple Pay 增值功能") do |cr|
      cr.extra_rounds = 1
      cr.quote_hkd = 3800
    end
    cafe.projects.find_or_create_by!(name: "網店") { |p| p.phase = :launch }

    # A signed-off project with a certificate
    yoga = Client.find_by!(code: "DEMOYOGA")
    yoga_user = User.find_by!(email_address: "client@demoyoga.example")
    form = yoga.projects.find_or_create_by!(name: "會員登記表") { |p| p.max_uat_rounds = 2 }
    if form.test_cases.empty?
      form.test_cases.create!(code: "TC-01", title: "填表提交", expected: "收到確認 email", source: :client)
      form.test_cases.create!(code: "TC-02", title: "必填欄位留空", expected: "顯示錯誤，唔會提交", source: :ae)
    end
    if form.uat_rounds.empty?
      round = form.open_next_round!
      round.test_results.each { |r| r.update!(status: :pass) }
      begin
        SignOff.sign!(round: round.reload, user: yoga_user, signer_name: "陳大文")
      rescue StandardError => e
        warn "Skipped the sign-off (#{e.class}: #{e.message}). Run bin/build-seal first."
      end
    end

    # Use up this month's rounds so the next change ticket asks for confirmation
    site = yoga.projects.find_by!(name: "品牌網站")
    plan = yoga.retainer_plan
    (plan.included_rounds - plan.rounds_used(Date.current)).times do |i|
      site.tickets.create!(opened_by: yoga_user, title: "改首頁 banner 文字 #{i + 1}", body: "換成聖誕優惠字眼")
    end

    # UAT signed outside the portal, system links and a monthly update for the site in maintenance
    if site.external_sign_offs.empty?
      signed = Rails.root.join("test/fixtures/files/signed.pdf")
      site.external_sign_offs.create!(position: 1, scope: "A", title: "內容驗收", signer_name: "陳大文",
                                      signed_on: 2.months.ago.to_date, countersigned_by: "Jeff Poon",
                                      statement: "我已逐頁閱讀網站文案同圖片，確認內容準確，同意以此版本上線。")
      site.external_sign_offs.create!(position: 2, scope: "final", title: "最終驗收", signer_name: "陳大文",
                                      signed_on: 7.weeks.ago.to_date, countersigned_by: "Jeff Poon", final: true,
                                      statement: "以上各節已完成，本系統符合驗收要求，同意上線。",
                                      document: { io: File.open(signed), filename: "UAT-最終驗收-已簽.pdf", content_type: "application/pdf" })
    end
    if site.system_links.empty?
      [
        [ :site, "品牌網站", "https://demoyoga.example", "Demo Yoga（hello@demoyoga.example）", nil ],
        [ :site, "課程報名表", "https://demoyoga.example/join", nil, "報名會即時寄 email 通知" ],
        [ :admin, "網站後台", "https://demoyoga.example/admin", "Demo Yoga", "連續 5 次錯密碼會鎖 15 分鐘" ],
        [ :service, "網域同 DNS（Cloudflare）", "https://dash.cloudflare.com", "Demo Yoga", nil ],
        [ :doc, "Admin 使用手冊", "https://docs.example/demoyoga-admin", nil, nil ]
      ].each_with_index do |(kind, label, url, owner, note), i|
        site.system_links.create!(kind: kind, label: label, url: url, account_owner: owner, note: note, position: i + 1)
      end
      site.update!(support_notes: "一般問題請喺 portal 開 ticket，工作日 24 小時內回覆。\n網站完全打唔開：WhatsApp 5123 4567（24 小時）。")
    end
    MonthlyUpdate.find_or_create_by!(client: yoga, month: Date.current.beginning_of_month) do |u|
      u.done_summary = "更新咗首頁 banner 同聖誕優惠字眼\n修正報名表喺 iPhone 嘅排版"
      u.next_steps = "加 FAQ 頁\n一月之前檢查 SSL 證書續期"
    end

    # A retainer under notice, with part of the handover done
    tutor = Client.find_or_create_by!(code: "DEMOTUTOR") do |c|
      c.name = "Demo 補習社"
      c.contact_email = "hello@demotutor.example"
    end
    User.find_or_create_by!(email_address: "client@demotutor.example") do |u|
      u.password = password
      u.role = :client
      u.client = tutor
    end
    tutor.projects.find_or_create_by!(name: "報名系統") { |p| p.phase = :maintenance }
    tutor_plan = tutor.retainer_plan ||
      tutor.create_retainer_plan!(monthly_fee_hkd: 1800, included_rounds: 2, extra_round_hkd: 400,
                                  starts_on: 4.months.ago.to_date.beginning_of_month, notice_days: 30)
    unless tutor_plan.notice_given?
      tutor_plan.give_notice!(by: :client, on: 10.days.ago.to_date)
      tutor_plan.handover_items.first(2).each { |item| item.mark!(done: true, user: admin) }
    end

    puts "UI states ready. Extra logins (password #{password}): #{cafe_user.email_address}, client@demotutor.example"
  end
end
