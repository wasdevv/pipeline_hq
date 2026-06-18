# frozen_string_literal: true

class FormFieldComponent < ViewComponent::Base
  INPUT_CLASSES = "mt-1 w-full rounded-md border border-zinc-300 bg-white px-3 py-2 text-sm shadow-sm placeholder:text-zinc-400 focus:border-indigo-500 focus:outline-none focus:ring-2 focus:ring-indigo-500/30 dark:border-zinc-700 dark:bg-zinc-900"

  def initialize(name:, label:, type: :text, form: nil, value: nil, hint: nil,
                 autocomplete: nil, autofocus: false, required: false,
                 inputmode: nil, data: {}, class_extra: nil, action_label: nil, action_path: nil)
    @name = name
    @label = label
    @type = type
    @form = form
    @value = value
    @hint = hint
    @autocomplete = autocomplete
    @autofocus = autofocus
    @required = required
    @inputmode = inputmode
    @data = data
    @class_extra = class_extra
    @action_label = action_label
    @action_path = action_path
  end

  def input_classes
    [ INPUT_CLASSES, @class_extra ].compact.join(" ")
  end

  def input_attrs
    {
      required: @required,
      autofocus: @autofocus,
      autocomplete: @autocomplete,
      inputmode: @inputmode,
      data: @data,
      class: input_classes
    }.compact
  end
end
