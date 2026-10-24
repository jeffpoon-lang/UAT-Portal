require "open3"

# 叫 Rust 嘅 uat-seal 計 digest。
# payload 會先做 canonical（key 排序），保證同一份內容每次計出同一個 digest。
class SealService
  BIN = Rails.root.join("bin/uat-seal").to_s
  GENESIS = "GENESIS".freeze

  class Error < StandardError; end

  def self.digest(payload, prev_digest = nil)
    raise Error, "未 build Rust binary，請先跑 bin/build-seal" unless File.executable?(BIN)

    out, err, status = Open3.capture3(BIN, "seal", prev_digest || GENESIS, stdin_data: canonical_json(payload))
    raise Error, "seal failed: #{err.strip}" unless status.success?

    out.strip
  end

  def self.canonical_json(payload) = canonical(payload).to_json

  def self.canonical(obj)
    case obj
    when Hash  then obj.to_h { |k, v| [ k.to_s, canonical(v) ] }.sort.to_h
    when Array then obj.map { |v| canonical(v) }
    else obj
    end
  end
end
