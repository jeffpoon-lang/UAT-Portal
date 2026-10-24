# UAT Portal

客戶 portal：追蹤 project 交付階段、UAT test case，之後加 UAT round、sign-off 同 maintenance ticket。
Sign-off 記錄用 Rust（`seal/`）計 SHA-256 hash chain，改過任何一條舊記錄都驗得出。

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

## Test

```bash
bin/rails test          # Rails（包括 SealService 叫 Rust）
cd seal && cargo test   # Rust
```

## 進度（跟 build plan）

- [x] 週末 1：Rails 骨架、登入、Client / Project / TestCase、admin CRUD、階段進度條、Rust seal
- [ ] 週末 2：UatRound、TestResult、Sign-off（hash chain）、verify、deploy
- [ ] 週末 3：Maintenance ticket、月尾報告、AI 摘要
- [ ] 週末 4：Test、README 架構圖、demo 片
