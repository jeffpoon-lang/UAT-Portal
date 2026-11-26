# 經 controller 送出上載咗嘅文件：先查權限，唔用公開嘅 blob 網址。
# 只有 PDF／PNG／JPG 喺瀏覽器直接打開，其他一律下載。
module SendsDocument
  private
    def send_document(attachment)
      raise ActiveRecord::RecordNotFound unless attachment.attached?

      blob = attachment.blob
      inline = ServableDocument::CONTENT_TYPES.include?(blob.content_type)
      response.headers["Cache-Control"] = "private, no-store"
      send_data blob.download, filename: blob.filename.to_s, type: blob.content_type,
                               disposition: inline ? "inline" : "attachment"
    end
end
