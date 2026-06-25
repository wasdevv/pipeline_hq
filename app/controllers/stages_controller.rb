# frozen_string_literal: true

class StagesController < ApplicationController
  include WorkspaceScoped

  before_action :set_stage, only: %i[show edit update destroy]

  def index
    @stages = policy_scope(Stage).order(position: :asc)
  end

  def show
    authorize @stage
  end

  def new
    @stage = current_workspace.stages.build
    authorize @stage
  end

  def edit
    authorize @stage
  end

  def create
    @stage = current_workspace.stages.build(stage_params)
    authorize @stage

    respond_to do |format|
      if @stage.save
        format.html { redirect_to @stage, notice: t("stages.created") }
        format.json { render :show, status: :created, location: @stage }
      else
        format.html { render :new, status: :unprocessable_content }
        format.json { render json: @stage.errors, status: :unprocessable_content }
      end
    end
  end

  def update
    authorize @stage

    respond_to do |format|
      if @stage.update(stage_params)
        format.html { redirect_to @stage, notice: t("stages.updated"), status: :see_other }
        format.json { render :show, status: :ok, location: @stage }
      else
        format.html { render :edit, status: :unprocessable_content }
        format.json { render json: @stage.errors, status: :unprocessable_content }
      end
    end
  end

  def destroy
    authorize @stage
    @stage.destroy!

    respond_to do |format|
      format.html { redirect_to stages_path, notice: t("stages.destroyed"), status: :see_other }
      format.json { head :no_content }
    end
  end

  private

  def set_stage
    @stage = current_workspace.stages.find(params.expect(:id))
  end

  def stage_params
    params.expect(stage: [ :name, :position, :color ])
  end
end
