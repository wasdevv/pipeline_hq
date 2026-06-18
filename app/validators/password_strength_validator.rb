# frozen_string_literal: true

class PasswordStrengthValidator < ActiveModel::EachValidator
  MIN_LENGTH = 12

  def validate_each(record, attribute, value)
    return if value.blank?

    if value.length < MIN_LENGTH
      record.errors.add(attribute, :too_short, count: MIN_LENGTH)
      return
    end

    classes = [ /[a-z]/, /[A-Z]/, /\d/, /[^a-zA-Z0-9]/ ].count { |re| value.match?(re) }
    record.errors.add(attribute, :weak) if classes < 3

    if pwned?(value)
      record.errors.add(attribute, :pwned)
    end
  end

  private

  def pwned?(value)
    Passwords::BreachCheck.call(value)
  rescue StandardError => e
    Rails.logger.warn("PasswordStrengthValidator: #{e.class} #{e.message}")
    false
  end
end
