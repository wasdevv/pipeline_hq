# frozen_string_literal: true

class ContactsController < ApplicationController
  include WorkspaceScoped

  before_action :set_contact, only: %i[show edit update destroy]

  def index
    @contacts = policy_scope(Contact).includes(:account).order(created_at: :desc)
  end

  def show
    authorize @contact
  end

  def new
    @contact = current_workspace.contacts.build
    authorize @contact
  end

  def edit
    authorize @contact
  end

  def create
    @contact = current_workspace.contacts.build(contact_params)
    authorize @contact

    respond_to do |format|
      if @contact.save
        format.html { redirect_to @contact, notice: t("contacts.created") }
        format.json { render :show, status: :created, location: @contact }
      else
        format.html { render :new, status: :unprocessable_content }
        format.json { render json: @contact.errors, status: :unprocessable_content }
      end
    end
  end

  def update
    authorize @contact

    respond_to do |format|
      if @contact.update(contact_params)
        format.html { redirect_to @contact, notice: t("contacts.updated"), status: :see_other }
        format.json { render :show, status: :ok, location: @contact }
      else
        format.html { render :edit, status: :unprocessable_content }
        format.json { render json: @contact.errors, status: :unprocessable_content }
      end
    end
  end

  def destroy
    authorize @contact
    @contact.destroy!

    respond_to do |format|
      format.html { redirect_to contacts_path, notice: t("contacts.destroyed"), status: :see_other }
      format.json { head :no_content }
    end
  end

  private

  def set_contact
    @contact = current_workspace.contacts.find(params.expect(:id))
  end

  def contact_params
    params.expect(contact: [ :account_id, :name, :email, :phone, :role ])
  end
end
