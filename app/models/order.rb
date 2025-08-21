class Order < ApplicationRecord
  belongs_to :seller
  has_many :order_items, dependent: :destroy
  has_many :products, through: :order_items
  has_many :returns, class_name: 'Return', foreign_key: 'original_order_id', dependent: :destroy
  has_many :original_exchanges, class_name: 'Exchange', foreign_key: 'original_order_id', dependent: :destroy
  has_many :new_exchanges, class_name: 'Exchange', foreign_key: 'new_order_id', dependent: :destroy
  
  accepts_nested_attributes_for :order_items, allow_destroy: true
  
  validates :external_id, presence: { message: "can't be blank" }
  validates :external_id, uniqueness: { scope: :seller_id, message: "já existe um pedido com este external_id nesta loja" }, if: :external_id?
  
  # Callback para atualizar o progresso das metas quando uma venda é criada
  after_create :update_goals_progress
  
  # Calcula o total bruto do pedido
  def total
    order_items.sum { |item| item.quantity * item.unit_price }
  end
  
  # Calcula o total líquido (descontando devoluções e trocas)
  def net_total
    gross_total = total
    returned_value = returns.sum(&:return_value)
    exchanged_value = original_exchanges.sum(:voucher_value)
    gross_total - returned_value - exchanged_value
  end
  
  # Valor total das devoluções
  def total_returned
    returns.sum(&:return_value)
  end
  
  private
  
  def update_goals_progress
    # Buscar metas ativas do vendedor
    seller_goals = Goal.where(seller_id: seller_id)
                      .where('start_date <= ? AND end_date >= ?', Date.current, Date.current)
                      .where(goal_type: :sales)
    
    # Buscar metas da loja
    store_goals = Goal.where(seller_id: nil)
                     .where('start_date <= ? AND end_date >= ?', Date.current, Date.current)
                     .where(goal_type: :sales)
                     .joins(:seller)
                     .where(sellers: { store_id: seller.store_id })
    
    # Buscar metas globais (sem seller_id)
    global_goals = Goal.where(seller_id: nil)
                      .where('start_date <= ? AND end_date >= ?', Date.current, Date.current)
                      .where(goal_type: :sales)
                      .where.not(id: store_goals.pluck(:id))
    
    all_goals = seller_goals + store_goals + global_goals
    
    all_goals.each do |goal|
      # Calcular o valor atual das vendas líquidas para esta meta
      if goal.goal_scope == 'individual'
        # Meta individual: somar vendas líquidas do vendedor no período da meta
        orders_in_period = Order.where(seller_id: goal.seller_id)
                               .where('orders.sold_at >= ? AND orders.sold_at <= ?', 
                                      goal.start_date, goal.end_date)
        current_sales = orders_in_period.sum(&:net_total)
      elsif goal.seller_id.present?
        # Meta da loja: somar vendas líquidas da loja no período da meta
        orders_in_period = Order.joins(:seller)
                               .where(sellers: { store_id: goal.seller.store_id })
                               .where('orders.sold_at >= ? AND orders.sold_at <= ?', 
                                      goal.start_date, goal.end_date)
        current_sales = orders_in_period.sum(&:net_total)
      else
        # Meta global: somar todas as vendas líquidas no período da meta
        orders_in_period = Order.where('orders.sold_at >= ? AND orders.sold_at <= ?', 
                                      goal.start_date, goal.end_date)
        current_sales = orders_in_period.sum(&:net_total)
      end
      
      # Atualizar o current_value da meta
      goal.update(current_value: current_sales)
    end
  end
end
