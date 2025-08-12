class Order < ApplicationRecord
  belongs_to :seller
  has_many :order_items, dependent: :destroy
  has_many :products, through: :order_items
  
  accepts_nested_attributes_for :order_items, allow_destroy: true
  
  validates :external_id, presence: true, uniqueness: true
  
  # Callback para atualizar o progresso das metas quando uma venda é criada
  after_create :update_goals_progress
  
  # Calcula o total do pedido
  def total
    order_items.sum { |item| item.quantity * item.unit_price }
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
      # Calcular o valor atual das vendas para esta meta
      if goal.goal_scope == 'individual'
        # Meta individual: somar vendas do vendedor no período da meta
        current_sales = Order.joins(:order_items)
                            .where(seller_id: goal.seller_id)
                            .where('orders.created_at >= ? AND orders.created_at <= ?', 
                                   goal.start_date.beginning_of_day, goal.end_date.end_of_day)
                            .sum('order_items.quantity * order_items.unit_price')
      elsif goal.seller_id.present?
        # Meta da loja: somar vendas da loja no período da meta
        current_sales = Order.joins(:order_items, :seller)
                            .where(sellers: { store_id: goal.seller.store_id })
                            .where('orders.created_at >= ? AND orders.created_at <= ?', 
                                   goal.start_date.beginning_of_day, goal.end_date.end_of_day)
                            .sum('order_items.quantity * order_items.unit_price')
      else
        # Meta global: somar todas as vendas no período da meta
        current_sales = Order.joins(:order_items)
                            .where('orders.created_at >= ? AND orders.created_at <= ?', 
                                   goal.start_date.beginning_of_day, goal.end_date.end_of_day)
                            .sum('order_items.quantity * order_items.unit_price')
      end
      
      # Atualizar o current_value da meta
      goal.update(current_value: current_sales)
    end
  end
end
