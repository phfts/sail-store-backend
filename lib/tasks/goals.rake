namespace :goals do
  desc "Recalcula o progresso de todas as metas ativas"
  task recalculate_all: :environment do
    puts "Recalculando progresso de todas as metas ativas..."
    
    # Buscar todas as metas ativas
    active_goals = Goal.where('start_date <= ? AND end_date >= ?', Date.current, Date.current)
    
    puts "Encontradas #{active_goals.count} metas ativas"
    
    active_goals.each do |goal|
      puts "Processando meta ID #{goal.id} - #{goal.description || 'Sem descrição'}"
      
      # Calcular o valor atual das vendas líquidas para esta meta
      if goal.goal_scope == 'individual' && goal.seller_id.present?
        # Meta individual: somar vendas líquidas do vendedor no período da meta
        orders_in_period = Order.where(seller_id: goal.seller_id)
                               .where('orders.created_at >= ? AND orders.created_at <= ?', 
                                      goal.start_date.beginning_of_day, goal.end_date.end_of_day)
        current_sales = orders_in_period.sum(&:net_total)
        
        seller_name = goal.seller&.name || "Vendedor ID #{goal.seller_id}"
        puts "  Meta individual para #{seller_name}: R$ #{current_sales}"
      else
        # Meta da loja ou meta global: somar todas as vendas líquidas no período da meta
        if goal.seller_id.present?
          # Meta de uma loja específica
          store_id = goal.seller.store_id
          orders_in_period = Order.joins(:seller)
                                 .where(sellers: { store_id: store_id })
                                 .where('orders.created_at >= ? AND orders.created_at <= ?', 
                                        goal.start_date.beginning_of_day, goal.end_date.end_of_day)
          current_sales = orders_in_period.sum(&:net_total)
          
          store_name = goal.seller.store.name
          puts "  Meta da loja #{store_name}: R$ #{current_sales}"
        else
          # Meta global: somar todas as vendas líquidas
          orders_in_period = Order.where('orders.created_at >= ? AND orders.created_at <= ?', 
                                        goal.start_date.beginning_of_day, goal.end_date.end_of_day)
          current_sales = orders_in_period.sum(&:net_total)
          
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
