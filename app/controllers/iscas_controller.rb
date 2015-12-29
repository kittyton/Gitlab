class IscasController < ApplicationController
  before_action :set_isca, only: [:show, :edit, :update, :destroy]

  respond_to :html

  def index
    @iscas = Isca.all
    respond_with(@iscas)
  end

  def show
    respond_with(@isca)
  end

  def new
    @isca = Isca.new
    respond_with(@isca)
  end

  def edit
  end

  def create
    @isca = Isca.new(isca_params)
    @isca.save
    respond_with(@isca)
  end

  def update
    @isca.update(isca_params)
    respond_with(@isca)
  end

  def destroy
    @isca.destroy
    respond_with(@isca)
  end

  private
    def set_isca
      @isca = Isca.find(params[:id])
    end

    def isca_params
      params[:isca]
    end
end
