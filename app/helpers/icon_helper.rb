# Inline SVG icons from app/assets/icons (Lucide, ISC licence).
#
#   icon("check")                          decorative, hidden from screen readers
#   icon("printer", class: "size-5")
#   icon("x", label: "關閉")               announced by screen readers
module IconHelper
  ICON_DIR = Rails.root.join("app/assets/icons")
  ICON_NAME = /\A[a-z0-9-]+\z/
  ICON_CACHE = Concurrent::Map.new

  def icon(name, label: nil, **options)
    css = options.fetch(:class, "size-4")
    a11y = label ? %(role="img" aria-label="#{ERB::Util.html_escape(label)}") : %(aria-hidden="true" focusable="false")
    # The SVG comes from a file in this repo, never from user input
    icon_svg(name.to_s).sub("<svg ", %(<svg class="#{ERB::Util.html_escape(css)}" #{a11y} )).html_safe
  end

  private
    def icon_svg(name)
      raise ArgumentError, "unknown icon #{name.inspect}" unless name.match?(ICON_NAME)

      read = -> {
        path = ICON_DIR.join("#{name}.svg")
        raise ArgumentError, "unknown icon #{name.inspect}" unless path.file?

        path.read.strip
      }
      Rails.env.development? ? read.call : ICON_CACHE.compute_if_absent(name, &read)
    end
end
