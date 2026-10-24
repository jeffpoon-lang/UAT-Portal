# UAT Portal

客戶 portal：追蹤 project 交付階段、UAT test case，之後加 UAT round、sign-off 同 maintenance ticket。
Sign-off 記錄用 Rust（`seal/`）計 SHA-256 hash chain，改過任何一條舊記錄都驗得出。

## 流程

1. 你（admin）建客戶、project、test case，撳「開 Round 1」
2. 客喺 portal 逐條剔 Pass／Fail／測唔到，寫 comment、上載截圖
3. 有 fail → 客撳「提交，等 IT 修正」→ 你改好開下一個 round
4. 超出合約 round 數 → 開 CR，客簽咗你撳批核，先開到新 round
5. 全部 pass → 客輸入全名、剔確認、簽署 → 出 UAT-{CLIENT}-{NNN} 證書，project 自動去 Launch
6. Sign-offs 頁撳「驗證成條 chain」→ Rust 由頭驗到尾，改過、刪過、調亂過都會報出嚟

## Stack

- **Rails 8.1**：portal、登入、CRUD（Postgres、Tailwind、Stimulus）
- **Rust**：`seal/` → `bin/uat-seal`，Rails 經 `SealService`（Open3 + stdin）叫佢
- 之後：OpenAI API 摘要 UAT comment

## 第一次喺 Mac 起

```bash
brew install postgresql@16 && brew services start postgresql@16
# Ruby 3.3+、Rust（rustup）要先裝好
bundle install
bin/build-seal          # build Rust binary，換機要重跑
bin/rails db:setup      # 建 DB + demo data（登入資料睇 db/seeds.rb）
bin/dev                 # http://localhost:3000
```

## Deploy（Render）

1. 將 repo push 上 GitHub
2. Render dashboard → New → Blueprint → 揀個 repo（用 `render.yaml`）
3. 填 `RAILS_MASTER_KEY`（`config/master.key` 內容）、`ADMIN_EMAIL`、`ADMIN_PASSWORD`
4. Dockerfile 會先 build Rust 再 build Rails；開 server 前自動跑 migration
5. Production 唔會落 demo data，只會用上面兩個變數建 admin

截圖存喺 `/rails/storage`，blueprint 已經掛咗永久 disk（Render 要 paid plan 先有 disk）。

## Test

```bash
bin/rails test          # Rails（包括 SealService 叫 Rust）
cd seal && cargo test   # Rust
```

## 進度（跟 build plan）

- [x] 週末 1：Rails 骨架、登入、Client / Project / TestCase、admin CRUD、階段進度條、Rust seal
- [x] 週末 2：UatRound、TestResult + 截圖、CR、Sign-off（hash chain）、Rust verify、audit 頁、Dockerfile + Render blueprint
- [ ] 週末 3：Maintenance ticket、月尾報告、AI 摘要
- [ ] 週末 4：Test、README 架構圖、demo 片
