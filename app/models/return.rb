class Return < ApplicationRecord
  # Relacionamentos
  belongs_to :seller
  belongs_to :store
  belongs_to :product, optional: true
  
  # Validações
  validates :external_id, presence: true, uniqueness: true
  validates :quantity_returned, presence: true, numericality: { greater_than: 0 }
  validates :processed_at, presence: true
  
  # Scopes
  scope :by_date_range, ->(start_date, end_date) { where(processed_at: start_date..end_date) }
  scope :by_seller, ->(seller_id) { where(seller_id: seller_id) }
  scope :by_store, ->(store_id) { where(store_id: store_id) }
  scope :by_product, ->(product_id) { where(product_id: product_id) }
  
  # Métodos
  def return_value
    return 0 unless product
    
    # Buscar o preço médio do produto na loja para calcular o valor da devolução
    # Como não temos mais acesso ao pedido original, usamos o preço médio
    average_price = product.order_items.joins(:order)
                           .where(orders: { seller_id: seller_id })
                           .average(:unit_price) || 0
    
    quantity_returned * average_price
  end
  
  def formatted_quantity
    quantity_returned.to_f
  end
end
