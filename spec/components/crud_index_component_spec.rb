# frozen_string_literal: true

require "rails_helper"

RSpec.describe CrudIndexComponent, type: :component do
  let(:account_a) { create(:account, name: "Acme Corp", industry: "SaaS") }
  let(:account_b) { create(:account, name: "Beta Inc", industry: "Fintech") }

  let(:base_args) do
    {
      title:    "Empresas",
      subtitle: "lista",
      records:  [],
      columns: [
        { label: "Nome",  value: ->(a) { a.name } },
        { label: "Setor", value: ->(a) { a.industry } }
      ],
      new_path:  "/accounts/new",
      new_label: "Nova empresa",
      show_path: ->(a) { "/accounts/#{a.id}" },
      edit_path: ->(a) { "/accounts/#{a.id}/edit" }
    }
  end

  context "with records" do
    it "renders one row per record" do
      render_inline(described_class.new(**base_args.merge(records: [ account_a, account_b ])))

      expect(page).to have_content("Acme Corp")
      expect(page).to have_content("Beta Inc")
    end

    it "renders the column headers" do
      render_inline(described_class.new(**base_args.merge(records: [ account_a ])))

      expect(page).to have_css("th", text: "Nome")
      expect(page).to have_css("th", text: "Setor")
      expect(page).to have_css("th", text: "Ações")
    end

    it "renders show / edit / delete actions per row" do
      render_inline(described_class.new(**base_args.merge(records: [ account_a ])))

      expect(page).to have_link("Ver", href: "/accounts/#{account_a.id}")
      expect(page).to have_link("Editar", href: "/accounts/#{account_a.id}/edit")
      expect(page).to have_button("Apagar")
    end

    it "applies right-alignment when column.align is :right" do
      args = base_args.merge(
        records: [ account_a ],
        columns: [ { label: "Valor", value: ->(_) { "1.000" }, align: :right } ]
      )
      render_inline(described_class.new(**args))
      expect(page).to have_css("td.text-right", text: "1.000")
    end
  end

  context "with empty records" do
    it "renders the empty state" do
      args = base_args.merge(
        records: [],
        empty_title: "Nenhuma empresa",
        empty_description: "comece criando",
        empty_action_label: "Cadastrar"
      )
      render_inline(described_class.new(**args))

      expect(page).to have_content("Nenhuma empresa")
      expect(page).to have_content("comece criando")
      expect(page).to have_link("Cadastrar", href: "/accounts/new")
    end

    it "does not render the table" do
      render_inline(described_class.new(**base_args.merge(records: [])))
      expect(page).to have_no_css("table")
    end
  end

  describe "#col_class" do
    it "returns right-aligned class for right columns" do
      component = described_class.new(**base_args)
      column = described_class::Column.new(label: "x", value: ->(_) { "" }, align: :right)
      expect(component.col_class(column)).to include("text-right")
    end

    it "returns left-aligned class otherwise" do
      component = described_class.new(**base_args)
      column = described_class::Column.new(label: "x", value: ->(_) { "" }, align: :left)
      expect(component.col_class(column)).not_to include("text-right")
    end
  end
end
