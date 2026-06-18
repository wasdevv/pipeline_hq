# frozen_string_literal: true

class ButtonPrimaryComponent < ViewComponent::Base
  CLASSES = "w-full rounded-md bg-zinc-900 px-4 py-2 text-sm font-medium text-white shadow-sm transition hover:bg-zinc-800 focus:outline-none focus:ring-2 focus:ring-zinc-900 focus:ring-offset-2 dark:bg-white dark:text-zinc-900 dark:hover:bg-zinc-100"

  def initialize(label:, type: :submit, form: nil)
    @label = label
    @type  = type
    @form  = form
  end
end
