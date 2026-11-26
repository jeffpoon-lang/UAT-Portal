# 喺 portal 以外簽咗嘅 UAT 聲明（例如紙本或者 PDF 簽名）。
# 只係記錄低簽咗咩、邊日簽、邊個簽，再附上簽咗嘅文件；
# 唔會入 SignOff 嘅 hash chain，因為內容唔係喺系統入面鎖定嘅。
# 標咗 final 嘅一份代表 UAT 驗收完成，之後唔使再開 round。
class ExternalSignOff < ApplicationRecord
  belongs_to :project
  has_one_attached :document

  validates :title, :signer_name, :signed_on, presence: { message: "唔可以留空" }
  validate :signed_on_not_in_future
  validate :document_is_pdf_or_image

  private
    def signed_on_not_in_future
      errors.add(:signed_on, "唔可以係未來日子") if signed_on && signed_on > Date.current
    end

    def document_is_pdf_or_image
      return unless document.attached?

      errors.add(:document, "只可以上載 PDF、PNG 或者 JPG") unless ServableDocument::CONTENT_TYPES.include?(document.content_type)
      errors.add(:document, "唔可以大過 10MB") if document.byte_size.to_i > 10.megabytes
    end
end
