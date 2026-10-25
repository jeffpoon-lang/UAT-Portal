# Production：每次 deploy 跑完 db:prepare，就用 ADMIN_EMAIL／ADMIN_PASSWORD 確保有 admin 帳號。
# seeds 嘅 production 部分係 idempotent（已經有就唔會重複建），喺同一個 process 入面跑，唔使多開一次 Rails。
if Rails.env.production?
  Rake::Task["db:prepare"].enhance do
    Rake::Task["db:seed"].invoke
  end
end
