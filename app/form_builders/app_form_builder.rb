# The default builder for every form_with. It gives each control the design
# system's class (call-site classes are added after it), marks a control with
# an error as aria-invalid, and adds two helpers:
#
#   <%= f.field :name, "客戶名", hint: "…" do %><%= f.text_field :name %><% end %>
#   <%= f.choice_group :priority, [ [ "low", "唔急" ], … ], legend: "有幾急" %>
class AppFormBuilder < ActionView::Helpers::FormBuilder
  FIELD_CLASSES = {
    text_field: "input", email_field: "input", password_field: "input", number_field: "input",
    telephone_field: "input", url_field: "input", search_field: "input",
    date_field: "input", month_field: "input", datetime_field: "input",
    text_area: "textarea", file_field: "file-input"
  }.freeze

  FIELD_CLASSES.each do |helper, css|
    define_method(helper) do |method, options = {}|
      super(method, decorate(method, options, css))
    end
  end

  def select(method, choices = nil, options = {}, html_options = {}, &block)
    super(method, choices, options, decorate(method, html_options, "select"), &block)
  end

  def collection_select(method, collection, value_method, text_method, options = {}, html_options = {})
    super(method, collection, value_method, text_method, options, decorate(method, html_options, "select"))
  end

  def check_box(method, options = {}, checked_value = "1", unchecked_value = "0")
    super(method, decorate(method, options, "checkbox"), checked_value, unchecked_value)
  end

  # A primary button unless the call site picks other classes. While the
  # request is in flight the button reads "處理中…", which matters when the
  # server is slow to answer.
  def submit(value = nil, options = {})
    value, options = nil, value if value.is_a?(Hash)
    options = options.dup
    options[:class] ||= "btn btn-primary"
    options[:data] = { turbo_submits_with: "處理中…" }.merge(options[:data] || {})
    super(value, options)
  end

  def field(method, label_text, hint: nil, optional: false, &block)
    @template.tag.div(class: "field") do
      label_content = @template.safe_join([ label_text, (@template.tag.span("（可選）", class: "label-optional") if optional) ].compact)
      @template.safe_join([
        label(method, label_content, class: "label"),
        @template.capture(&block),
        (@template.tag.p(hint, class: "hint") if hint),
        (@template.tag.p(error_text(method), class: "field-error", id: error_id(method)) if error?(method))
      ].compact)
    end
  end

  # Radio buttons drawn as pills. tones maps a value to an extra class
  # (choice-pass / choice-fail / choice-blocked).
  def choice_group(method, choices, legend:, tones: {}, grid: "grid grid-cols-2 gap-2 sm:flex sm:flex-wrap", hint: nil, legend_class: "label")
    @template.tag.fieldset(class: "field") do
      @template.safe_join([
        @template.tag.legend(legend, class: legend_class),
        @template.tag.div(class: grid) do
          @template.safe_join(choices.map { |value, text|
            @template.tag.label(class: [ "choice", tones[value] ].compact.join(" ")) do
              @template.safe_join([ radio_button(method, value, class: "sr-only"), text ])
            end
          })
        end,
        (@template.tag.p(hint, class: "hint") if hint),
        (@template.tag.p(error_text(method), class: "field-error", id: error_id(method)) if error?(method))
      ].compact)
    end
  end

  private
    def decorate(method, options, css)
      options = options.dup
      options[:class] = [ css, options[:class] ].compact_blank.join(" ")
      if error?(method)
        options[:"aria-invalid"] = "true"
        options[:"aria-describedby"] = [ options[:"aria-describedby"], error_id(method) ].compact.join(" ")
      end
      options
    end

    # A belongs_to field (client_id) reports its error on the association (client)
    def error_keys(method) = [ method.to_sym, method.to_s.delete_suffix("_id").to_sym ].uniq

    def error?(method)
      object.respond_to?(:errors) && error_keys(method).any? { |k| object.errors.include?(k) }
    end

    def error_text(method)
      error_keys(method).flat_map { |k| object.errors.full_messages_for(k) }.to_sentence
    end

    def error_id(method) = "#{@object_name.to_s.tr('[]', '_').squeeze('_').delete_suffix('_')}_#{method}_error"
end
