class Order < ApplicationRecord
  belongs_to :seller
  has_many :order_items, dependent: :destroy
  has_many :products, through: :order_items
  
  validates :external_id, presence: true, uniqueness: true
  
  # Calcula o total do pedido
  def total
    order_items.sum { |item| item.quantity * item.unit_price }
  end
end
