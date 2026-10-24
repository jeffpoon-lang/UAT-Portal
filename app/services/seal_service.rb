require "open3"

# 叫 Rust 嘅 uat-seal 計 digest 同驗證 chain。
# payload 會先做 canonical（key 排序），保證同一份內容每次計出同一個 digest。
class SealService
  BIN = Rails.root.join("bin/uat-seal").to_s
  GENESIS = "GENESIS".freeze

  class Error < StandardError; end

  VerifyResult = Data.define(:ok, :count, :broken_index, :reason) do
    def ok? = ok
  end

  def self.digest(payload, prev_digest = nil) = digest_json(canonical_json(payload), prev_digest)

  def self.digest_json(json, prev_digest = nil)
    out = run("seal", prev_digest || GENESIS, stdin: json)
    out.strip
  end

  # records：[[digest, prev_digest, payload_json], ...]，由第一條開始
  def self.verify(records)
    input = records.map { |row| row.join("\t") + "\n" }.join
    out, status = run_raw("verify", stdin: input)
    line = out.strip

    if status.success? && line =~ /\AOK (\d+)\z/
      VerifyResult.new(ok: true, count: $1.to_i, broken_index: nil, reason: nil)
    elsif line =~ /\ABROKEN (\d+) (\w+)\z/
      VerifyResult.new(ok: false, count: records.size, broken_index: $1.to_i, reason: $2)
    else
      raise Error, "verify 出咗意料之外嘅結果：#{line}"
    end
  end

  def self.canonical_json(payload) = canonical(payload).to_json

  def self.canonical(obj)
    case obj
    when Hash  then obj.to_h { |k, v| [ k.to_s, canonical(v) ] }.sort.to_h
    when Array then obj.map { |v| canonical(v) }
    else obj
    end
  end

  def self.run(*args, stdin:)
    out, status, err = run_raw(*args, stdin: stdin, with_err: true)
    raise Error, "uat-seal #{args.first} failed: #{err.strip}" unless status.success?
    out
  end

  def self.run_raw(*args, stdin:, with_err: false)
    raise Error, "未 build Rust binary，請先跑 bin/build-seal" unless File.executable?(BIN)

    out, err, status = Open3.capture3(BIN, *args, stdin_data: stdin)
    with_err ? [ out, status, err ] : [ out, status ]
  end
  private_class_method :run, :run_raw
end
