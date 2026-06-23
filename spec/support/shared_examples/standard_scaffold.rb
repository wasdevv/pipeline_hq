# frozen_string_literal: true

RSpec.shared_examples "a standard scaffold" do |model:, factory:, attribute_path:|
  let(:record)       { create(factory) }
  let(:resource_key) { attribute_path.singularize.to_sym }
  let(:index_path)   { send("#{attribute_path}_path") }
  let(:show_path)    { send("#{attribute_path.singularize}_path", record) }
  let(:new_path)     { send("new_#{attribute_path.singularize}_path") }
  let(:edit_path)    { send("edit_#{attribute_path.singularize}_path", record) }

  it "GET index responds with 200" do
    record
    get index_path
    expect(response).to have_http_status(:ok)
  end

  it "GET show responds with 200" do
    get show_path
    expect(response).to have_http_status(:ok)
  end

  it "GET new responds with 200" do
    get new_path
    expect(response).to have_http_status(:ok)
  end

  it "GET edit responds with 200" do
    get edit_path
    expect(response).to have_http_status(:ok)
  end

  it "POST create persists and redirects" do
    expect { post index_path, params: { resource_key => create_params } }
      .to change(model, :count).by(1)
    expect(response).to have_http_status(:found)
  end

  it "PATCH update succeeds" do
    patch show_path, params: { resource_key => update_params }
    expect(response).to have_http_status(:see_other)
  end

  it "DELETE destroy removes the record" do
    record
    expect { delete show_path }.to change(model, :count).by(-1)
  end
end
