# frozen_string_literal: true

class WorkspacesController < ApplicationController
  include RecordsDomainEvents

  skip_after_action :record_domain_event
  after_action :record_domain_event, only: :update, if: :audit_eligible?

  before_action :set_workspace, only: %i[show edit update]

  def new
    @workspace = Workspace.new
    authorize @workspace
  end

  def create
    authorize Workspace.new
    result = Workspaces::Create.call(user: current_user, name: workspace_params[:name])

    if result.success?
      session[:current_workspace_id] = result.payload.id
      Current.workspace = result.payload
      redirect_to workspace_path(result.payload), notice: t("workspaces.created")
    else
      @workspace = result.payload || Workspace.new
      @workspace.errors.merge!(result.errors) if result.errors
      render :new, status: :unprocessable_content
    end
  end

  def show
    authorize @workspace
  end

  def edit
    authorize @workspace
  end

  def update
    authorize @workspace

    if @workspace.update(workspace_params)
      redirect_to workspace_path(@workspace), notice: t("workspaces.updated")
    else
      render :edit, status: :unprocessable_content
    end
  end

  private

  def set_workspace
    @workspace = Workspace.find(params[:id])
  end

  def workspace_params
    params.expect(workspace: [ :name ])
  end

  def audit_subject
    @workspace
  end

  def audit_workspace
    @workspace
  end

  def audit_kind
    "workspace.updated"
  end
end
