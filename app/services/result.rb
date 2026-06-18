# frozen_string_literal: true

class Result
  attr_reader :code, :payload, :errors

  def self.success(code = :ok, payload = nil)        = new(true,  code, payload, nil)
  def self.failure(code, errors = nil, payload = nil) = new(false, code, payload, errors)

  def initialize(success, code, payload, errors)
    @success = success
    @code    = code
    @payload = payload
    @errors  = errors
  end

  def success? = @success
  def failure? = !@success
end
