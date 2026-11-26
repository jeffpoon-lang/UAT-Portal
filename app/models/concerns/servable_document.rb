# 上載咗嘅文件只接受呢幾種格式，咁先可以安全咁喺瀏覽器直接打開
# （唔收 SVG、HTML 呢類可以行 script 嘅格式）
module ServableDocument
  CONTENT_TYPES = %w[application/pdf image/png image/jpeg].freeze
end
