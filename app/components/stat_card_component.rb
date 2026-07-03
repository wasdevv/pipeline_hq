# frozen_string_literal: true

class StatCardComponent < ViewComponent::Base
  def initialize(label:, value:, hint: nil, icon: nil, accent: :indigo)
    @label = label
    @value = value
    @hint = hint
    @icon = icon
    @accent = accent
  end

  def accent_classes
    case @accent
    when :emerald then "bg-emerald-100 text-emerald-600 dark:bg-emerald-950 dark:text-emerald-400"
    when :amber   then "bg-amber-100 text-amber-600 dark:bg-amber-950 dark:text-amber-400"
    when :rose    then "bg-rose-100 text-rose-600 dark:bg-rose-950 dark:text-rose-400"
    when :sky     then "bg-sky-100 text-sky-600 dark:bg-sky-950 dark:text-sky-400"
    else "bg-indigo-100 text-indigo-600 dark:bg-indigo-950 dark:text-indigo-400"
    end
  end

  def icon_path
    case @icon
    when :money    then "M12 1v22M17 5H9.5a3.5 3.5 0 0 0 0 7h5a3.5 3.5 0 0 1 0 7H6"
    when :trophy   then "M8 21h8M12 17v4M7 4h10v5a5 5 0 0 1-10 0V4zM7 4H3v3a4 4 0 0 0 4 4M17 4h4v3a4 4 0 0 1-4 4"
    when :briefcase then "M3 7h18v13H3zM8 7V5a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2M3 13h18"
    when :building then "M3 21h18M5 21V7l7-4 7 4v14M9 9h1M9 13h1M9 17h1M14 9h1M14 13h1M14 17h1"
    when :users    then "M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2M9 11a4 4 0 1 0 0-8 4 4 0 0 0 0 8z"
    when :pulse    then "M22 12h-4l-3 9L9 3l-3 9H2"
    else "M3 5h18v14H3z"
    end
  end
end
