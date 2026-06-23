# frozen_string_literal: true

require "rails_helper"

RSpec.describe NavCardComponent, type: :component do
  it "renders title, subtitle, and link to href" do
    render_inline(described_class.new(title: "Deals", subtitle: "Pipeline", href: "/deals"))

    expect(page).to have_content("Deals")
    expect(page).to have_content("Pipeline")
    expect(page).to have_link(href: "/deals")
  end
end
