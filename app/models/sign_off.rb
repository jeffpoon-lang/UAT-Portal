# UAT sign-off：簽嗰刻將所有結果鎖成 payload_json，用 Rust 計 digest，
# digest 包埋上一條 sign-off 嘅 digest，所以成個系統嘅 sign-off 係一條 chain。
class SignOff < ApplicationRecord
  belongs_to :project
  belongs_to :uat_round
  belongs_to :signed_by, class_name: "User"

  validates :signer_name, :signed_at, :doc_number, :payload_json, :digest, :prev_digest, presence: true

  # 建立咗就唔准改
  def readonly? = persisted?

  def self.sign!(round:, user:, signer_name:)
    raise UatRound::NotAllowed, "請輸入簽署人全名" if signer_name.to_s.strip.empty?

    transaction do
      # 鎖住成張表，防止兩個人同時簽搶同一個 prev_digest
      connection.execute("LOCK TABLE sign_offs IN EXCLUSIVE MODE")
      round.lock!
      raise UatRound::NotAllowed, "呢個 round 唔可以再簽" unless round.status_open?
      raise UatRound::NotAllowed, "要全部 test case pass 先可以 sign-off" unless round.all_passed?

      project = round.project
      prev = order(:id).last&.digest || SealService::GENESIS
      signed_at = Time.current.utc.change(usec: 0)
      doc_number = next_doc_number(project.client)

      payload_json = SealService.canonical_json(
        doc_number: doc_number,
        client: { code: project.client.code, name: project.client.name },
        project: { id: project.id, name: project.name },
        round: round.number,
        signer: { name: signer_name.strip, email: user.email_address },
        signed_at: signed_at.iso8601,
        results: round.test_results.map { |r|
          { code: r.test_case.code, title: r.test_case.title, status: r.status, comment: r.comment.to_s }
        }
      )

      sign_off = create!(
        project: project, uat_round: round, signed_by: user, signer_name: signer_name.strip,
        signed_at: signed_at, doc_number: doc_number, payload_json: payload_json,
        prev_digest: prev, digest: SealService.digest_json(payload_json, prev)
      )
      round.update!(status: :signed_off, closed_at: signed_at)
      project.update!(phase: :launch) if project.phase_uat?
      sign_off
    end
  end

  # 由第一條驗到最後一條；任何一條被改過都會報出嚟
  def self.verify_chain
    SealService.verify(order(:id).map { |s| [ s.digest, s.prev_digest, s.payload_json ] })
  end

  def self.next_doc_number(client)
    n = joins(:project).where(projects: { client_id: client.id }).count + 1
    format("UAT-%s-%03d", client.code, n)
  end

  def payload = JSON.parse(payload_json)
  def short_digest = digest.first(12)
end
