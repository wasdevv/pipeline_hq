# frozen_string_literal: true

class ButtonSecondaryComponent < ViewComponent::Base
  CLASSES = "rounded-md border border-zinc-300 px-4 py-2 text-sm font-medium hover:bg-zinc-50 dark:border-zinc-700 dark:hover:bg-zinc-800"
  DANGER  = "rounded-md border border-rose-300 px-4 py-2 text-sm font-medium text-rose-700 hover:bg-rose-50 dark:border-rose-900 dark:text-rose-300 dark:hover:bg-rose-950"

  def initialize(label:, path:, method: nil, variant: :default, confirm: nil)
    @label = label
    @path = path
    @method = method
    @variant = variant
    @confirm = confirm
  end

  def classes
    @variant == :danger ? DANGER : CLASSES
  end

  def data
    @confirm ? { turbo_confirm: @confirm } : {}
  end
end
