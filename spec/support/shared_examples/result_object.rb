# frozen_string_literal: true

RSpec.shared_examples "a successful Result" do |code:|
  it "returns a success Result with code :#{code}" do
    expect(result).to be_success
    expect(result.code).to eq(code)
  end
end

RSpec.shared_examples "a failed Result" do |code:|
  it "returns a failure Result with code :#{code}" do
    expect(result).to be_failure
    expect(result.code).to eq(code)
  end
end
