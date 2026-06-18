# frozen_string_literal: true

module TwoFactor
  class Enroll
    def self.call(user:)
      secret = ROTP::Base32.random
      uri = ROTP::TOTP.new(secret, issuer: "PipelineHQ").provisioning_uri(user.email_address)
      qr  = RQRCode::QRCode.new(uri).as_svg(module_size: 4, standalone: true)

      Result.success(:enrolled, { secret: secret, uri: uri, qr_svg: qr })
    end
  end
end
