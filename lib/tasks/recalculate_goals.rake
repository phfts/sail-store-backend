namespace :goals do
  desc "Recalcular o progresso de todas as metas"
  task recalculate_progress: :environment do
    puts "Recalculando progresso de todas as metas..."
    
    Goal.find_each do |goal|
      # Calcular o valor atual das vendas para esta meta
      if goal.goal_scope == 'individual'
        # Meta individual: somar vendas do vendedor no período da meta
        current_sales = Order.joins(:order_items)
                            .where(seller_id: goal.seller_id)
                            .where('orders.sold_at >= ? AND orders.sold_at <= ?', 
                                   goal.start_date, goal.end_date)
                            .sum('order_items.quantity * order_items.unit_price')
      elsif goal.seller_id.present?
        # Meta da loja: somar vendas da loja no período da meta
        current_sales = Order.joins(:order_items, :seller)
                            .where(sellers: { store_id: goal.seller.store_id })
                            .where('orders.sold_at >= ? AND orders.sold_at <= ?', 
                                   goal.start_date, goal.end_date)
                            .sum('order_items.quantity * order_items.unit_price')
      else
        # Meta global: somar todas as vendas no período da meta
        current_sales = Order.joins(:order_items)
                            .where('orders.sold_at >= ? AND orders.sold_at <= ?', 
                                   goal.start_date, goal.end_date)
                            .sum('order_items.quantity * order_items.unit_price')
      end
      
      # Atualizar o current_value da meta
      goal.update(current_value: current_sales)
      
      progress = goal.progress_percentage
      puts "Meta #{goal.id} (#{goal.seller&.name || 'Loja'}): R$ #{current_sales} / R$ #{goal.target_value} (#{progress}%)"
    end
    
    puts "Recálculo concluído!"
  end
end
