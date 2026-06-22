# frozen_string_literal: true

require "rails_helper"

RSpec.describe FormFieldComponent, type: :component do
  it "renders a labelled text input by default" do
    render_inline(described_class.new(name: :email, label: "Email"))
    expect(page).to have_field("Email")
  end

  it "supports password type" do
    render_inline(described_class.new(name: :password, label: "Senha", type: :password))
    expect(page).to have_field("Senha", type: "password")
  end

  it "passes through autocomplete and inputmode" do
    render_inline(described_class.new(name: :otp, label: "Code", autocomplete: "one-time-code", inputmode: "numeric"))
    expect(page).to have_css('input[autocomplete="one-time-code"][inputmode="numeric"]')
  end

  it "marks the field as required" do
    render_inline(described_class.new(name: :email, label: "Email", required: true))
    expect(page).to have_css("input[required]")
  end

  it "concatenates extra classes" do
    render_inline(described_class.new(name: :code, label: "Code", class_extra: "tracking-widest"))
    expect(page).to have_css("input.tracking-widest")
  end

  it "renders action_label as a link to action_path when both are present" do
    render_inline(described_class.new(name: :password, label: "Senha", type: :password,
                                      action_label: "Esqueci", action_path: "/passwords/new"))
    expect(page).to have_link("Esqueci", href: "/passwords/new")
  end

  it "renders a hint when provided" do
    render_inline(described_class.new(name: :code, label: "Code", hint: "6 digits"))
    expect(page).to have_content("6 digits")
  end

  describe "#input_classes" do
    it "returns base classes when no extra" do
      component = described_class.new(name: :x, label: "X")
      expect(component.input_classes).to eq(FormFieldComponent::INPUT_CLASSES)
    end

    it "appends extra when provided" do
      component = described_class.new(name: :x, label: "X", class_extra: "extra-class")
      expect(component.input_classes).to include("extra-class")
      expect(component.input_classes).to include(FormFieldComponent::INPUT_CLASSES)
    end
  end
end
