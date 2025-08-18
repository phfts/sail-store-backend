# frozen_string_literal: true

namespace :sales do
  desc "Calcular vendas brutas de um vendedor específico em um determinado mês"
  task :seller_monthly_gross, [:seller_name, :year, :month] => :environment do |task, args|
    # Validar argumentos
    unless args[:seller_name] && args[:year] && args[:month]
      puts "Uso: rake sales:seller_monthly_gross[NOME_DO_VENDEDOR,ANO,MES]"
      puts "Exemplo: rake sales:seller_monthly_gross['NATHALIA DIONISIO MALAQUIAS',2025,7]"
      exit 1
    end

    seller_name = args[:seller_name]
    year = args[:year].to_i
    month = args[:month].to_i

    # Validar ano e mês
    if year < 2020 || year > 2030
      puts "❌ Ano inválido: #{year}. Use um ano entre 2020 e 2030."
      exit 1
    end

    if month < 1 || month > 12
      puts "❌ Mês inválido: #{month}. Use um mês entre 1 e 12."
      exit 1
    end

    # Definir período
    start_date = Date.new(year, month, 1)
    end_date = start_date.end_of_month

    puts "🔍 Buscando vendas para:"
    puts "   Vendedor: #{seller_name}"
    puts "   Período: #{start_date.strftime('%d/%m/%Y')} a #{end_date.strftime('%d/%m/%Y')}"
    puts "   " + "="*50

    begin
      # Buscar vendedor por nome (busca case-insensitive)
      seller = Seller.where("UPPER(name) = ?", seller_name.upcase).first

      unless seller
        puts "❌ Vendedor não encontrado: #{seller_name}"
        puts "\n💡 Vendedores disponíveis:"
        
        # Mostrar vendedores similares
        similar_sellers = Seller.where("UPPER(name) LIKE ?", "%#{seller_name.upcase}%")
        if similar_sellers.any?
          puts "   Nomes similares encontrados:"
          similar_sellers.each do |s|
            puts "   - #{s.name} (ID: #{s.id}, Loja: #{s.store.name})"
          end
        else
          puts "   Primeiros 10 vendedores na base:"
          Seller.limit(10).each do |s|
            puts "   - #{s.name} (ID: #{s.id}, Loja: #{s.store.name})"
          end
        end
        exit 1
      end

      # Informações do vendedor
      puts "✅ Vendedor encontrado:"
      puts "   Nome: #{seller.name}"
      puts "   ID: #{seller.id}"
      puts "   Loja: #{seller.store.name}"
      puts "   Empresa: #{seller.company.name}"
      puts ""

      # Buscar pedidos do vendedor no período usando sold_at
      orders = Order.joins(:order_items)
                   .where(seller_id: seller.id)
                   .where('orders.sold_at >= ? AND orders.sold_at <= ?', 
                          start_date.beginning_of_day, end_date.end_of_day)

      total_orders = orders.distinct.count
      total_items = orders.sum('order_items.quantity')
      gross_sales = orders.sum('order_items.quantity * order_items.unit_price')

      puts "📊 RESULTADOS - VENDAS BRUTAS:"
      puts "   Total de Pedidos: #{total_orders}"
      puts "   Total de Itens: #{total_items}"
      puts "   Vendas Brutas: #{format_currency(gross_sales)}"
      puts ""

      # Detalhamento por produto (top 10)
      if total_orders > 0
        puts "🏆 TOP 10 PRODUTOS VENDIDOS:"
        
        # Buscar vendas por produto através dos order_items
        product_sales = OrderItem.joins(:product, :order)
                                .where(order: orders.distinct)
                                .group('products.name')
                                .sum('order_items.quantity * order_items.unit_price')
                                .sort_by { |name, value| -value }
                                .first(10)

        product_sales.each_with_index do |(product_name, sales_value), index|
          puts "   #{index + 1}. #{product_name}: #{format_currency(sales_value)}"
        end
        puts ""

        # Vendas por dia do mês
        puts "📅 VENDAS POR DIA:"
        daily_sales = {}
        
        # Agrupar vendas por dia usando uma consulta mais eficiente
        OrderItem.joins(:order)
                 .where(order: orders.distinct)
                 .where('orders.sold_at >= ? AND orders.sold_at <= ?', 
                        start_date.beginning_of_day, end_date.end_of_day)
                 .group("DATE(orders.sold_at)")
                 .sum('order_items.quantity * order_items.unit_price')
                 .each do |date_key, sales|
                   # date_key pode ser uma string ou Date dependendo do driver do DB
                   date = date_key.is_a?(String) ? Date.parse(date_key) : date_key
                   daily_sales[date] = sales
                 end

        daily_sales.sort.each do |date, sales|
          day_name = date.strftime('%A')
          puts "   #{date.strftime('%d/%m')} (#{day_name}): #{format_currency(sales)}"
        end
        puts ""

        # Estatísticas adicionais
        working_days = daily_sales.keys.count
        avg_per_working_day = working_days > 0 ? gross_sales / working_days : 0
        avg_ticket = total_orders > 0 ? gross_sales / total_orders : 0
        avg_items_per_order = total_orders > 0 ? total_items.to_f / total_orders : 0

        puts "📈 ESTATÍSTICAS:"
        puts "   Dias Trabalhados: #{working_days}"
        puts "   Média por Dia Trabalhado: #{format_currency(avg_per_working_day)}"
        puts "   Ticket Médio: #{format_currency(avg_ticket)}"
        puts "   Produtos por Atendimento: #{avg_items_per_order.round(2)}"
        puts ""

        # Comparação com meta (se existir)
        current_goal = seller.goals
                            .where('start_date <= ? AND end_date >= ?', start_date, end_date)
                            .where(goal_scope: 'individual')
                            .first

        if current_goal
          goal_progress = current_goal.target_value > 0 ? (gross_sales / current_goal.target_value) * 100 : 0
          puts "🎯 META DO PERÍODO:"
          puts "   Meta: #{format_currency(current_goal.target_value)}"
          puts "   Atual: #{format_currency(gross_sales)}"
          puts "   Atingimento: #{goal_progress.round(1)}%"
          
          if goal_progress >= 100
            puts "   Status: ✅ META ATINGIDA!"
          elsif goal_progress >= 70
            puts "   Status: 🟡 Quase lá!"
          else
            puts "   Status: 🔴 Precisa melhorar"
          end
        else
          puts "ℹ️  Nenhuma meta individual encontrada para este período."
        end

      else
        puts "ℹ️  Nenhuma venda encontrada para este vendedor no período especificado."
        
        # Verificar se tem vendas em outros meses
        other_sales = Order.joins(:order_items)
                          .where(seller_id: seller.id)
                          .where('orders.sold_at IS NOT NULL')
                          .limit(5)

        if other_sales.any?
          puts "\n💡 Últimas vendas deste vendedor:"
          other_sales.each do |order|
            order_total = order.order_items.sum { |item| item.quantity * item.unit_price }
            puts "   #{order.sold_at.strftime('%d/%m/%Y')}: #{format_currency(order_total)}"
          end
        end
      end

    rescue => e
      puts "❌ Erro ao processar: #{e.message}"
      puts "   #{e.backtrace.first}"
      exit 1
    end

    puts "\n" + "="*50
    puts "✅ Relatório concluído com sucesso!"
  end

  private

  def format_currency(value)
    return "R$ 0,00" if value.nil? || value.zero?
    
    # Formatar em reais brasileiros
    formatted = sprintf("%.2f", value.to_f)
    integer_part, decimal_part = formatted.split('.')
    
    # Adicionar separadores de milhares
    integer_part = integer_part.reverse.gsub(/(\d{3})(?=\d)/, '\\1.').reverse
    
    "R$ #{integer_part},#{decimal_part}"
  end
end
