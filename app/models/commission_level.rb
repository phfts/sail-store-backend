class CommissionLevel < ApplicationRecord
  belongs_to :store
  
  validates :name, presence: true
  validates :achievement_percentage, presence: true, numericality: { greater_than: 0, less_than_or_equal_to: 100 }
  validates :commission_percentage, presence: true, numericality: { greater_than: 0, less_than_or_equal_to: 100 }
  validates :achievement_percentage, uniqueness: { scope: :store_id }
  
  scope :active, -> { where(active: true) }
  scope :ordered_by_achievement, -> { order(achievement_percentage: :asc) }
  
  def display_name
    "#{name} (#{achievement_percentage}% atingimento - #{commission_percentage}% comissão)"
  end
end
