# frozen_string_literal: true

class DashboardPreferencesController < ApplicationController
  def edit
    @sections = sections_for_form
  end

  def update
    result = UserDashboardPreferences::Update.call(
      user: current_user,
      sections: sections_param
    )

    if result.success?
      redirect_to root_path, notice: t("dashboard_preferences.updated"), status: :see_other
    else
      @sections = sections_for_form
      flash.now[:alert] = t("dashboard_preferences.failed")
      render :edit, status: :unprocessable_content
    end
  end

  private

  def sections_for_form
    prefs = current_user.dashboard_preferences.index_by(&:section)
    UserDashboardPreference::SECTIONS.each_with_index.map do |section, idx|
      pref = prefs[section]
      {
        section: section,
        enabled: pref ? pref.enabled : true,
        position: pref ? pref.position : idx
      }
    end.sort_by { |s| s[:position] }
  end

  def sections_param
    raw = params.fetch(:sections, {})
    raw = raw.values if raw.is_a?(ActionController::Parameters) || raw.is_a?(Hash)
    raw.map do |s|
      s = s.permit(:section, :enabled, :position) if s.respond_to?(:permit)
      s.to_h.symbolize_keys
    end
  end
end
