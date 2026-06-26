# frozen_string_literal: true

class ActivitiesController < ApplicationController
  include WorkspaceScoped
  include RecordsDomainEvents

  before_action :set_activity, only: %i[show edit update destroy]

  def index
    @activities = policy_scope(Activity).includes(:deal).order(occurred_at: :desc)
  end

  def show
    authorize @activity
  end

  def new
    @activity = current_workspace.activities.build
    authorize @activity
  end

  def edit
    authorize @activity
  end

  def create
    @activity = current_workspace.activities.build(activity_params)
    authorize @activity

    respond_to do |format|
      if @activity.save
        format.html { redirect_to @activity, notice: t("activities.created") }
        format.json { render :show, status: :created, location: @activity }
      else
        format.html { render :new, status: :unprocessable_content }
        format.json { render json: @activity.errors, status: :unprocessable_content }
      end
    end
  end

  def update
    authorize @activity

    respond_to do |format|
      if @activity.update(activity_params)
        format.html { redirect_to @activity, notice: t("activities.updated"), status: :see_other }
        format.json { render :show, status: :ok, location: @activity }
      else
        format.html { render :edit, status: :unprocessable_content }
        format.json { render json: @activity.errors, status: :unprocessable_content }
      end
    end
  end

  def destroy
    authorize @activity
    @activity.destroy!

    respond_to do |format|
      format.html { redirect_to activities_path, notice: t("activities.destroyed"), status: :see_other }
      format.json { head :no_content }
    end
  end

  private

  def set_activity
    @activity = current_workspace.activities.find(params.expect(:id))
  end

  def activity_params
    params.expect(activity: [ :deal_id, :kind, :subject, :body, :occurred_at ])
  end
end
