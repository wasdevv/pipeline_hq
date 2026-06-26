# frozen_string_literal: true

class AccountsController < ApplicationController
  include WorkspaceScoped
  include RecordsDomainEvents

  before_action :set_account, only: %i[show edit update destroy]

  def index
    @accounts = policy_scope(Account).order(created_at: :desc)
  end

  def show
    authorize @account
  end

  def new
    @account = current_workspace.accounts.build
    authorize @account
  end

  def edit
    authorize @account
  end

  def create
    @account = current_workspace.accounts.build(account_params)
    authorize @account

    respond_to do |format|
      if @account.save
        format.html { redirect_to @account, notice: t("accounts.created") }
        format.json { render :show, status: :created, location: @account }
      else
        format.html { render :new, status: :unprocessable_content }
        format.json { render json: @account.errors, status: :unprocessable_content }
      end
    end
  end

  def update
    authorize @account

    respond_to do |format|
      if @account.update(account_params)
        format.html { redirect_to @account, notice: t("accounts.updated"), status: :see_other }
        format.json { render :show, status: :ok, location: @account }
      else
        format.html { render :edit, status: :unprocessable_content }
        format.json { render json: @account.errors, status: :unprocessable_content }
      end
    end
  end

  def destroy
    authorize @account
    @account.destroy!

    respond_to do |format|
      format.html { redirect_to accounts_path, notice: t("accounts.destroyed"), status: :see_other }
      format.json { head :no_content }
    end
  end

  private

  def set_account
    @account = current_workspace.accounts.find(params.expect(:id))
  end

  def account_params
    params.expect(account: [ :name, :industry, :website, :notes ])
  end
end
