# frozen_string_literal: true

require "rails_helper"

RSpec.describe ButtonPrimaryComponent, type: :component do
  it "renders a submit input with the label" do
    render_inline(described_class.new(label: "Save"))
    expect(page).to have_css('input[type="submit"][value="Save"]')
  end

  it "applies the canonical primary classes" do
    render_inline(described_class.new(label: "Save"))
    expect(page).to have_css('input.bg-zinc-900')
  end

  it "uses the form helper's submit when given a form" do
    form_double = Class.new do
      def submit(label, **)
        "<input type='submit' value='#{label}' data-form-bound='true'>".html_safe
      end
    end.new

    render_inline(described_class.new(label: "Save", form: form_double))
    expect(page).to have_css("input[data-form-bound='true']")
  end
end
