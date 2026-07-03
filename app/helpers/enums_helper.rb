# frozen_string_literal: true

module EnumsHelper
  MISSING_TRANSLATION = "translation missing"

  def translate_enum(model, field, value, fallback: nil)
    return fallback if value.blank?

    key = "enums.#{model}.#{field}.#{value}"
    translated = t(key, default: "")
    return translated if translated.present? && !translated.start_with?(MISSING_TRANSLATION)

    fallback || value.to_s
  end

  def enum_options_for(model, field, values)
    values.map { |v| [ translate_enum(model, field, v), v.to_s ] }
  end
end
