namespace :goals do
  desc "Recalcula o progresso de todas as metas ativas"
  task recalculate_all: :environment do
    puts "Recalculando progresso de todas as metas ativas..."
    
    # Buscar todas as metas ativas
    active_goals = Goal.where('start_date <= ? AND end_date >= ?', Date.current, Date.current)
    
    puts "Encontradas #{active_goals.count} metas ativas"
    
    active_goals.each do |goal|
      puts "Processando meta ID #{goal.id} - #{goal.description || 'Sem descrição'}"
      
      # Calcular o valor atual das vendas para esta meta
      if goal.goal_scope == 'individual' && goal.seller_id.present?
        # Meta individual: somar vendas do vendedor no período da meta
        current_sales = Order.joins(:order_items)
                            .where(seller_id: goal.seller_id)
                            .where('orders.created_at >= ? AND orders.created_at <= ?', 
                                   goal.start_date.beginning_of_day, goal.end_date.end_of_day)
                            .sum('order_items.quantity * order_items.unit_price')
        
        seller_name = goal.seller&.name || "Vendedor ID #{goal.seller_id}"
        puts "  Meta individual para #{seller_name}: R$ #{current_sales}"
      else
        # Meta da loja ou meta global: somar todas as vendas no período da meta
        if goal.seller_id.present?
          # Meta de uma loja específica
          store_id = goal.seller.store_id
          current_sales = Order.joins(:order_items, :seller)
                              .where(sellers: { store_id: store_id })
                              .where('orders.created_at >= ? AND orders.created_at <= ?', 
                                     goal.start_date.beginning_of_day, goal.end_date.end_of_day)
                              .sum('order_items.quantity * order_items.unit_price')
          
          store_name = goal.seller.store.name
          puts "  Meta da loja #{store_name}: R$ #{current_sales}"
        else
          # Meta global: somar todas as vendas
          current_sales = Order.joins(:order_items)
                              .where('orders.created_at >= ? AND orders.created_at <= ?', 
                                     goal.start_date.beginning_of_day, goal.end_date.end_of_day)
                              .sum('order_items.quantity * order_items.unit_price')
          
          puts "  Meta global: R$ #{current_sales}"
        end
      end
      
      # Atualizar o current_value da meta
      old_value = goal.current_value
      goal.update(current_value: current_sales)
      
      progress = goal.progress_percentage
      puts "  Progresso: #{old_value} -> #{current_sales} (#{progress}%)"
      puts "  Meta: R$ #{goal.target_value}"
      puts ""
    end
    
    puts "Recálculo concluído!"
  end
end
