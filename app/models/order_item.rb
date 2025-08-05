class OrderItem < ApplicationRecord
  belongs_to :order
  belongs_to :product
  belongs_to :store
  
  validates :quantity, presence: true, numericality: { greater_than: 0 }
  validates :unit_price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  
  # Calcula o subtotal do item
  def subtotal
    quantity * unit_price
  end
end
