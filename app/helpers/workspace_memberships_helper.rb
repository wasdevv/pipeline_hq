# frozen_string_literal: true

module WorkspaceMembershipsHelper
  ROLE_BADGE_CLASSES = {
    "owner"  => "bg-indigo-100 text-indigo-800 dark:bg-indigo-900 dark:text-indigo-200",
    "admin"  => "bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-200",
    "member" => "bg-zinc-100 text-zinc-700 dark:bg-zinc-800 dark:text-zinc-300",
    "viewer" => "bg-zinc-100 text-zinc-500 dark:bg-zinc-800 dark:text-zinc-400"
  }.freeze

  def role_badge_classes(role)
    ROLE_BADGE_CLASSES[role.to_s] || ROLE_BADGE_CLASSES["member"]
  end
end
