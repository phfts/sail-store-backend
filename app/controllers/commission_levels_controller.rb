class CommissionLevelsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_store
  before_action :set_commission_level, only: [:show, :update, :destroy]

  def index
    @commission_levels = @store.commission_levels.ordered_by_achievement
    render json: @commission_levels
  end

  def show
    render json: @commission_level
  end

  def create
    @commission_level = @store.commission_levels.build(commission_level_params)
    
    if @commission_level.save
      render json: @commission_level, status: :created
    else
      render_validation_errors(@commission_level)
    end
  end

  def update
    if @commission_level.update(commission_level_params)
      render json: @commission_level
    else
      render_validation_errors(@commission_level)
    end
  end

  def destroy
    @commission_level.destroy
    head :no_content
  end

  private

  def set_store
    @store = Store.find_by!(slug: params[:store_slug])
  end

  def set_commission_level
    @commission_level = @store.commission_levels.find(params[:id])
  end

  def commission_level_params
    params.require(:commission_level).permit(:name, :achievement_percentage, :commission_percentage, :active)
  end
end
