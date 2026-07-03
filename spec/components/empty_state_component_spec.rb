# frozen_string_literal: true

require "rails_helper"

RSpec.describe EmptyStateComponent, type: :component do
  it "renders the title" do
    render_inline(described_class.new(title: "Nada por aqui"))
    expect(page).to have_content("Nada por aqui")
  end

  it "renders the description when present" do
    render_inline(described_class.new(title: "vazio", description: "comece criando um item"))
    expect(page).to have_content("comece criando um item")
  end

  it "renders the action link when label and path are provided" do
    render_inline(described_class.new(title: "vazio", action_label: "Criar", action_path: "/new"))
    expect(page).to have_link("Criar", href: "/new")
  end

  it "renders an SVG icon" do
    render_inline(described_class.new(icon: :building, title: "vazio"))
    expect(page).to have_css("svg")
  end

  describe "#icon_path" do
    %i[building users briefcase columns activity inbox].each do |icon|
      it "returns a non-empty path for :#{icon}" do
        component = described_class.new(icon: icon, title: "x")
        expect(component.icon_path).to be_a(String)
        expect(component.icon_path).not_to be_empty
      end
    end

    it "falls back to default path for unknown icons" do
      component = described_class.new(icon: :unknown_xyz, title: "x")
      expect(component.icon_path).to be_a(String)
      expect(component.icon_path).not_to be_empty
    end
  end
end
