# frozen_string_literal: true

class Rack::Attack
  cache.store = Rails.cache

  throttle("logins/ip", limit: 20, period: 5.minutes) do |req|
    req.ip if req.path == "/session" && req.post?
  end

  throttle("logins/email", limit: 10, period: 5.minutes) do |req|
    if req.path == "/session" && req.post?
      req.params["email_address"].to_s.strip.downcase.presence
    end
  end

  throttle("signups/ip", limit: 10, period: 5.minutes) do |req|
    req.ip if req.path == "/sign_up" && req.post?
  end

  throttle("passwords/ip", limit: 10, period: 5.minutes) do |req|
    req.ip if req.path == "/passwords" && req.post?
  end

  self.throttled_responder = ->(_env) {
    [ 429, { "content-type" => "text/plain" }, [ "Muitas tentativas. Aguarde alguns minutos." ] ]
  }
end
