class Return < ApplicationRecord
  # Relacionamentos
  belongs_to :original_order, class_name: 'Order', optional: true
  belongs_to :product, optional: true
  
  # Delegações para acessar seller através da order
  delegate :seller, to: :original_order, allow_nil: true
  
  # Validações
  validates :external_id, presence: true, uniqueness: true
  validates :quantity_returned, presence: true, numericality: { greater_than: 0 }
  validates :processed_at, presence: true
  
  # Scopes
  scope :by_date_range, ->(start_date, end_date) { where(processed_at: start_date..end_date) }
  scope :by_seller, ->(seller_id) { joins(:original_order).where(orders: { seller_id: seller_id }) }
  scope :by_product, ->(product_id) { where(product_id: product_id) }
  
  # Métodos
  def return_value
    return 0 unless original_order && product
    
    # Busca o item original da venda para pegar o preço unitário
    original_item = original_order.order_items.find_by(product: product)
    return 0 unless original_item
    
    quantity_returned * original_item.unit_price
  end
  
  def formatted_quantity
    quantity_returned.to_f
  end
end
