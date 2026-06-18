# frozen_string_literal: true

module Users
  class Register
    def self.call(...) = new(...).call

    def initialize(params:, request: nil)
      @params  = params
      @request = request
    end

    def call
      user = User.new(@params)
      return Result.failure(:invalid, user.errors, user) unless user.save

      Users::SendConfirmationEmail.call(user)
      AuthEvents::Record.call(kind: :signup, user: user, request: @request)

      Result.success(:registered, user)
    end
  end
end
