# frozen_string_literal: true

class DealsController < ApplicationController
  include WorkspaceScoped

  before_action :set_deal, only: %i[show edit update destroy]

  def index
    @deals = policy_scope(Deal).includes(:account, :stage, :contact).order(created_at: :desc)
  end

  def show
    authorize @deal
  end

  def new
    @deal = current_workspace.deals.build
    authorize @deal
  end

  def edit
    authorize @deal
  end

  def create
    @deal = current_workspace.deals.build(deal_params)
    authorize @deal

    respond_to do |format|
      if @deal.save
        format.html { redirect_to @deal, notice: t("deals.created") }
        format.json { render :show, status: :created, location: @deal }
      else
        format.html { render :new, status: :unprocessable_content }
        format.json { render json: @deal.errors, status: :unprocessable_content }
      end
    end
  end

  def update
    authorize @deal

    respond_to do |format|
      if @deal.update(deal_params)
        format.html { redirect_to @deal, notice: t("deals.updated"), status: :see_other }
        format.json { render :show, status: :ok, location: @deal }
      else
        format.html { render :edit, status: :unprocessable_content }
        format.json { render json: @deal.errors, status: :unprocessable_content }
      end
    end
  end

  def destroy
    authorize @deal
    @deal.destroy!

    respond_to do |format|
      format.html { redirect_to deals_path, notice: t("deals.destroyed"), status: :see_other }
      format.json { head :no_content }
    end
  end

  private

  def set_deal
    @deal = current_workspace.deals.find(params.expect(:id))
  end

  def deal_params
    params.expect(deal: [ :title, :account_id, :contact_id, :stage_id, :amount_cents, :currency, :expected_close_on, :status ])
  end
end
