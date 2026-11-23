require "test_helper"

class AppFormBuilderTest < ActionView::TestCase
  setup { @ticket = Ticket.new }

  def render_form(&block)
    render inline: "<%= form_with(model: @ticket, url: '/t', builder: AppFormBuilder) { |f| capture(f, &blk) } %>", locals: { blk: block }
  end

  test "controls get the design system class and keep the call site's classes" do
    render_form { |f| f.text_field(:title, class: "font-mono") + f.text_area(:body) + f.select(:priority, %w[low normal]) }
    assert_select "input#ticket_title.input.font-mono"
    assert_select "textarea#ticket_body.textarea"
    assert_select "select#ticket_priority.select"
  end

  test "a field with an error is marked invalid and shows its message" do
    @ticket.errors.add(:title, :blank)
    render_form { |f| f.field(:title, "標題") { f.text_field(:title) } }
    assert_select "label.label[for=ticket_title]", "標題"
    assert_select "input#ticket_title[aria-invalid=true][aria-describedby=ticket_title_error]"
    assert_select "p#ticket_title_error.field-error", /blank/
  end

  test "a field without an error has no error markup" do
    render_form { |f| f.field(:title, "標題", hint: "一句講完", optional: true) { f.text_field(:title) } }
    assert_select "input#ticket_title:not([aria-invalid])"
    assert_select "p.hint", "一句講完"
    assert_select "span.label-optional"
    assert_select ".field-error", count: 0
  end

  test "choice groups draw radio buttons as pills" do
    render_form { |f| f.choice_group(:priority, [ %w[low 唔急], %w[urgent 緊急] ], legend: "有幾急", tones: { "urgent" => "choice-fail" }) }
    assert_select "fieldset legend", "有幾急"
    assert_select "label.choice input[type=radio][value=low].sr-only"
    assert_select "label.choice.choice-fail input[value=urgent]"
  end

  test "submit is a primary button that says it's working while the request runs" do
    render_form { |f| f.submit("提交") }
    assert_select "input[type=submit].btn.btn-primary[value=提交][data-turbo-submits-with]"
  end
end
