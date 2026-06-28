# frozen_string_literal: true

module UserDashboardPreferences
  class Update
    def self.call(user:, sections:)
      new(user, sections).call
    end

    def initialize(user, sections)
      @user = user
      @sections = Array(sections)
    end

    def call
      return Result.failure(:invalid) if @sections.empty?

      UserDashboardPreference.transaction do
        @sections.each_with_index do |attrs, idx|
          section = attrs[:section].to_s
          next unless UserDashboardPreference::SECTIONS.include?(section)

          pref = @user.dashboard_preferences.find_or_initialize_by(section: section)
          pref.enabled  = ActiveModel::Type::Boolean.new.cast(attrs.fetch(:enabled, true))
          pref.position = attrs[:position].presence&.to_i || idx
          pref.save!
        end
      end

      Result.success(:saved, @user.dashboard_preferences.ordered)
    rescue ActiveRecord::RecordInvalid => e
      Result.failure(:invalid, e.record.errors)
    end
  end
end
