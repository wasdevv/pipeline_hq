# frozen_string_literal: true

require "rails_helper"

RSpec.describe ButtonSecondaryComponent, type: :component do
  it "renders a link to the path with the label" do
    render_inline(described_class.new(label: "Cancel", path: "/somewhere"))
    expect(page).to have_link("Cancel", href: "/somewhere")
  end

  it "applies the default classes" do
    render_inline(described_class.new(label: "Cancel", path: "/x"))
    expect(page).to have_css("a.border-zinc-300")
  end

  it "applies danger classes for the :danger variant" do
    render_inline(described_class.new(label: "Delete", path: "/x", variant: :danger))
    expect(page).to have_css("a.border-rose-300")
  end

  it "includes turbo_confirm when confirm and method are set" do
    render_inline(described_class.new(label: "Delete", path: "/x", method: :delete, confirm: "Sure?"))
    expect(page).to have_css('[data-turbo-confirm="Sure?"]')
  end

  it "renders a button_to form when method is set" do
    render_inline(described_class.new(label: "Delete", path: "/x", method: :delete))
    expect(page).to have_css('form[action="/x"] button', text: "Delete")
  end

  describe "#classes" do
    it "returns default classes for the default variant" do
      component = described_class.new(label: "x", path: "/x")
      expect(component.classes).to eq(ButtonSecondaryComponent::CLASSES)
    end

    it "returns danger classes for the :danger variant" do
      component = described_class.new(label: "x", path: "/x", variant: :danger)
      expect(component.classes).to eq(ButtonSecondaryComponent::DANGER)
    end
  end

  describe "#data" do
    it "is empty without confirm" do
      component = described_class.new(label: "x", path: "/x")
      expect(component.data).to eq({})
    end

    it "includes turbo_confirm when confirm is set" do
      component = described_class.new(label: "x", path: "/x", confirm: "Sure?")
      expect(component.data).to eq({ turbo_confirm: "Sure?" })
    end
  end
end
