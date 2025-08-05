namespace :cleanup do
  desc "Limpa todos os dados das lojas (sellers, sales, orders, schedules, etc.)"
  task clear_store_data: :environment do
    puts "🧹 Iniciando limpeza de dados das lojas..."
    
    # Contadores para relatório
    total_stores = Store.count
    total_sellers = Seller.count
    total_orders = Order.count
    total_order_items = OrderItem.count
    total_schedules = Schedule.count
    total_absences = Absence.count
    total_goals = Goal.count
    total_commission_levels = CommissionLevel.count
    total_shifts = Shift.count
    
    puts "📊 Dados atuais:"
    puts "   - Lojas: #{total_stores}"
    puts "   - Vendedores: #{total_sellers}"
    puts "   - Pedidos: #{total_orders}"
    puts "   - Itens de pedido: #{total_order_items}"
    puts "   - Agendamentos: #{total_schedules}"
    puts "   - Ausências: #{total_absences}"
    puts "   - Metas: #{total_goals}"
    puts "   - Níveis de comissão: #{total_commission_levels}"
    puts "   - Turnos: #{total_shifts}"
    
    puts "\n⚠️  ATENÇÃO: Esta operação irá deletar TODOS os dados das lojas!"
    puts "   Isso inclui vendedores, vendas, pedidos, agendamentos, etc."
    puts "   Os dados de usuários e categorias/produtos NÃO serão afetados."
    
    print "\n🤔 Confirma que deseja continuar? (digite 'SIM' para confirmar): "
    confirmation = STDIN.gets.chomp
    
    if confirmation != 'SIM'
      puts "❌ Operação cancelada pelo usuário."
      exit
    end
    
    puts "\n🗑️  Iniciando deleção..."
    
    begin
      # Inicia transação para garantir consistência
      ActiveRecord::Base.transaction do
        # Deleta dados relacionados às lojas
        puts "   - Deletando agendamentos..."
        Schedule.delete_all
        
        puts "   - Deletando ausências..."
        Absence.delete_all
        
        puts "   - Deletando metas..."
        Goal.delete_all
        
        puts "   - Deletando itens de pedido..."
        OrderItem.delete_all
        
        puts "   - Deletando pedidos..."
        Order.delete_all
        
        puts "   - Deletando vendedores..."
        Seller.delete_all
        
        puts "   - Deletando turnos..."
        Shift.delete_all
        
        puts "   - Deletando níveis de comissão..."
        CommissionLevel.delete_all
        
        puts "   - Deletando lojas..."
        Store.delete_all
      end
      
      puts "\n✅ Limpeza concluída com sucesso!"
      puts "📊 Dados restantes:"
      puts "   - Usuários: #{User.count}"
      puts "   - Categorias: #{Category.count}"
      puts "   - Produtos: #{Product.count}"
      puts "   - Logs de login: #{LoginLog.count}"
      
    rescue => e
      puts "\n❌ Erro durante a limpeza: #{e.message}"
      puts "🔍 Detalhes do erro: #{e.backtrace.first}"
      raise e
    end
  end
  
  desc "Limpa apenas dados de vendas e pedidos (mantém lojas e vendedores)"
  task clear_sales_data: :environment do
    puts "🧹 Iniciando limpeza de dados de vendas e pedidos..."
    
    # Contadores para relatório
    total_orders = Order.count
    total_order_items = OrderItem.count
    
    puts "📊 Dados atuais:"
    puts "   - Pedidos: #{total_orders}"
    puts "   - Itens de pedido: #{total_order_items}"
    
    puts "\n⚠️  ATENÇÃO: Esta operação irá deletar TODOS os dados de vendas e pedidos!"
    puts "   As lojas, vendedores e outros dados serão mantidos."
    
    print "\n🤔 Confirma que deseja continuar? (digite 'SIM' para confirmar): "
    confirmation = STDIN.gets.chomp
    
    if confirmation != 'SIM'
      puts "❌ Operação cancelada pelo usuário."
      exit
    end
    
    puts "\n🗑️  Iniciando deleção..."
    
    begin
      # Inicia transação para garantir consistência
      ActiveRecord::Base.transaction do
        puts "   - Deletando itens de pedido..."
        OrderItem.delete_all
        
        puts "   - Deletando pedidos..."
        Order.delete_all
      end
      
      puts "\n✅ Limpeza de vendas concluída com sucesso!"
      
    rescue => e
      puts "\n❌ Erro durante a limpeza: #{e.message}"
      puts "🔍 Detalhes do erro: #{e.backtrace.first}"
      raise e
    end
  end
end
