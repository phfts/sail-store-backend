require 'csv'

namespace :import do
  desc "Import SOUQ Iguatemi SP data for 2025 only"
  task souq_iguatemi_2025: :environment do
    # Setup do arquivo de log
    log_file = Rails.root.join('log', 'souq_iguatemi_2025_import.log')
    File.delete(log_file) if File.exist?(log_file)
    
    def log_progress(message, log_file_path)
      timestamp = Time.current.strftime("%H:%M:%S")
      log_message = "[#{timestamp}] #{message}"
      puts log_message
      File.open(log_file_path, 'a') { |f| f.puts log_message }
    end
    
    log_progress("🚀 Importação SOUQ Iguatemi SP - Apenas 2025 iniciada...", log_file)
    log_progress("   📅 Período: 2025", log_file)
    log_progress("   🏪 Loja: SOUQ - SP - IGUATEMI SP", log_file)
    log_progress("   📝 Acompanhe o progresso em: #{log_file}", log_file)
    
    # Configuração da loja Iguatemi SP
    store_config = {
      cnpj: "16945787002148",
      name: "SOUQ - SP - IGUATEMI SP",
      external_id: "iguatemi_sp", 
      data_path: "/home/paulo/work/sail/analysis/data/souq/SOUQ_-_SP_-_IGUATEMI_SP/dados"
    }
    
    # Funções auxiliares
    def parse_br_money(value)
      return 0.0 if value.blank? || value == "0,0000"
      value.gsub(',', '.').to_f
    end
    
    def parse_br_date(date_str)
      return nil if date_str.blank?
      begin
        Date.strptime(date_str, "%d/%m/%Y %H:%M:%S")
      rescue
        begin
          Date.strptime(date_str, "%d/%m/%Y")
        rescue
          nil
        end
      end
    end
    
    def extract_seller_name(obs)
      return nil if obs.blank?
      match = obs.match(/Nome do Vendedor: ([^|]+)/)
      match ? match[1].strip : nil
    end
    
    # 1. LIMPEZA DOS DADOS 2025 DA LOJA IGUATEMI SP
    log_progress("🧹 Limpando dados existentes de 2025 da loja Iguatemi SP...", log_file)
    
    # Encontrar a empresa Souq
    company = Company.find_by(name: ["Souq", "SOUQ"])
    unless company
      log_progress("❌ Empresa Souq não encontrada. Execute primeiro a importação completa.", log_file)
      exit 1
    end
    
    # Encontrar a loja Iguatemi SP
    store = Store.find_by(cnpj: store_config[:cnpj], company_id: company.id)
    unless store
      log_progress("🏪 Criando loja Iguatemi SP...", log_file)
      store = Store.create!(
        cnpj: store_config[:cnpj],
        name: store_config[:name],
        external_id: store_config[:external_id],
        company_id: company.id
      )
      log_progress("✅ Loja criada: #{store.name} (ID: #{store.id})", log_file)
    end
    
    # Deletar dados de 2025 da loja Iguatemi SP
    log_progress("🗑️  Deletando dados de 2025 da loja Iguatemi SP...", log_file)
    
    # Deletar trocas de 2025
    exchanges_2025 = Exchange.joins(:seller)
                             .where(sellers: { store_id: store.id })
                             .where('EXTRACT(year FROM processed_at) = ?', 2025)
    exchanges_count = exchanges_2025.count
    exchanges_2025.delete_all
    log_progress("   - #{exchanges_count} trocas deletadas", log_file)
    
    # Deletar devoluções de 2025
    returns_2025 = Return.joins(original_order: :seller)
                         .where(sellers: { store_id: store.id })
                         .where('EXTRACT(year FROM processed_at) = ?', 2025)
    returns_count = returns_2025.count
    returns_2025.delete_all
    log_progress("   - #{returns_count} devoluções deletadas", log_file)
    
    # Deletar order_items de 2025
    items_2025 = OrderItem.joins(order: :seller)
                          .where(sellers: { store_id: store.id })
                          .where('EXTRACT(year FROM orders.sold_at) = ?', 2025)
    items_count = items_2025.count
    items_2025.delete_all
    log_progress("   - #{items_count} itens de pedidos deletados", log_file)
    
    # Deletar orders de 2025 (órfãos)
    orders_2025 = Order.joins(:seller)
                       .where(sellers: { store_id: store.id })
                       .where('EXTRACT(year FROM sold_at) = ?', 2025)
                       .left_joins(:order_items)
                       .where(order_items: { id: nil })
    orders_count = orders_2025.count
    orders_2025.delete_all
    log_progress("   - #{orders_count} pedidos deletados", log_file)
    
    log_progress("✅ Limpeza de dados 2025 concluída!", log_file)
    
    # 2. ENCONTRAR OU CRIAR CATEGORIA
    category = Category.find_by(company_id: company.id) || 
               Category.create!(
                 name: "Produtos Souq",
                 company_id: company.id,
                 external_id: "souq_products"
               )
    
    # 3. PROCESSAR DADOS DE 2025
    log_progress("🏪 Processando dados de 2025 da loja: #{store_config[:name]}", log_file)
    
    # Mapas para evitar duplicatas
    sellers_map = {}
    products_map = {}
    orders_map = {}
    
    # Carregar vendedores existentes da loja
    store.sellers.each do |seller|
      sellers_map["#{store.id}_#{seller.external_id.split('_').last}"] = seller if seller.external_id
    end
    
    # Carregar produtos existentes
    Product.all.each do |product|
      products_map[product.external_id] = product if product.external_id
    end
    
    # Configuração para 2025
    year_info = { year: 2025, file_suffix: "2025-01-01_endDate=2025-08-12" }
    
    log_progress("   📅 Processando ano #{year_info[:year]}...", log_file)
    
    movement_file = "#{store_config[:data_path]}/LinxMovimento_store=#{store_config[:cnpj]}_beginDate=#{year_info[:file_suffix]}.csv"
    
    unless File.exist?(movement_file)
      log_progress("     ❌ Arquivo não encontrado: #{movement_file}", log_file)
      exit 1
    end
    
    # Estatísticas
    stats = {
      sellers: 0,
      products: 0,
      orders: 0,
      items: 0,
      returns: 0,
      exchanges: 0,
      total_value: 0.0
    }
    
    year_sales = 0
    year_rows = 0
    
    log_progress("     📁 Processando arquivo: #{movement_file}", log_file)
    
    CSV.foreach(movement_file, headers: true, encoding: 'UTF-8') do |row|
      year_rows += 1
      operacao = row['operacao']&.strip
      
      # Processar vendas (S), devoluções (D) e combinações (DS, etc.)
      next unless operacao&.include?('S') || operacao&.include?('D') || operacao&.strip == 'E'
      next if row['cancelado'] == 'S' # Pular cancelados
      
      # Determinar tipo da operação
      is_return_or_exchange = operacao&.include?('D')
      is_transfer = operacao&.strip == 'E'
      
      # Verificar ano
      data_lancamento = parse_br_date(row['data_lancamento'])
      next unless data_lancamento && data_lancamento.year == year_info[:year]
      
      # Contar apenas vendas reais, não devoluções
      unless is_return_or_exchange || is_transfer
        year_sales += 1
        
        # Progress indicator
        if year_sales % 1000 == 0
          log_progress("     📦 #{year_sales} vendas processadas...", log_file)
        end
      end
      
      # Criar/encontrar vendedor
      seller_code = row['cod_vendedor']
      seller_key = "#{store.id}_#{seller_code}"
      unless sellers_map[seller_key]
        seller_name = extract_seller_name(row['obs']) || "Vendedor #{seller_code}"
        
        # Nome único por loja
        unique_name = seller_name
        counter = 1
        while Seller.exists?(name: unique_name, store_id: store.id)
          unique_name = "#{seller_name} (#{counter})"
          counter += 1
        end
        
        seller = Seller.create!(
          external_id: "#{store_config[:external_id]}_#{seller_code}",
          company_id: company.id,
          name: unique_name,
          store_id: store.id
        )
        
        sellers_map[seller_key] = seller
        stats[:sellers] += 1
        log_progress("     👤 Novo vendedor: #{seller.name}", log_file)
      end
      
      # Criar/encontrar produto
      product_code = row['cod_produto']
      unless products_map[product_code]
        product = Product.find_or_create_by!(external_id: product_code) do |p|
          p.name = "Produto #{product_code}"
          p.sku = row['cod_barra'] || product_code
          p.category_id = category.id
        end
        products_map[product_code] = product
        stats[:products] += 1 if product.id_previously_changed?
      end
      
      # Criar/encontrar pedido
      documento = row['documento']
      order_key = "#{year_info[:year]}_#{store.id}_#{documento}_#{data_lancamento.strftime('%Y%m%d')}"
      unless orders_map[order_key]
        order_external_id = "#{year_info[:year]}_#{store_config[:external_id]}_#{documento}"
        
        order = Order.find_or_create_by!(external_id: order_external_id) do |o|
          o.seller_id = sellers_map[seller_key].id
          o.sold_at = data_lancamento
        end
        orders_map[order_key] = order
        stats[:orders] += 1 if order.id_previously_changed?
      end
      
      # Se for devolução/troca, criar Return ou Exchange
      if is_return_or_exchange
        unit_price = parse_br_money(row['preco_unitario'])
        quantity = row['quantidade'].to_i
        total_amount = -(quantity * unit_price) # Valor negativo para devolução
        
        desc_cfop = row['desc_cfop'] || ''
        
        # Determinar se é troca ou devolução baseado na descrição CFOP
        is_return = desc_cfop.downcase.include?('devoluc') || desc_cfop.include?('DevoluÃ§Ã£o')
        is_exchange = !is_return && (desc_cfop.downcase.include?('troca') || !row['obs'].to_s.empty?)
        
        if is_exchange
          # Criar Exchange
          exchange_external_id = "#{year_info[:year]}_#{store_config[:external_id]}_exchange_#{documento}_#{row['ordem']}"
          
          exchange = Exchange.find_or_create_by!(external_id: exchange_external_id) do |ex|
            ex.voucher_number = documento
            ex.voucher_value = unit_price.abs # Valor positivo para voucher
            ex.original_document = documento
            ex.customer_code = row['codigo_cliente']
            ex.exchange_type = 'TROCA SIMPLES'
            ex.is_credit = true # Crédito para o cliente
            ex.processed_at = data_lancamento
            ex.seller_id = sellers_map[seller_key].id
          end
          
          stats[:exchanges] = (stats[:exchanges] || 0) + 1
        elsif is_return
          # Criar Return
          return_external_id = "#{year_info[:year]}_#{store_config[:external_id]}_return_#{documento}_#{product_code}_#{row['ordem']}"
          
          return_obj = Return.find_or_create_by!(external_id: return_external_id) do |ret|
            ret.original_sale_id = row['identificador']
            ret.product_external_id = product_code
            ret.original_transaction = row['transacao']
            ret.return_transaction = row['transacao']
            ret.quantity_returned = quantity
            ret.processed_at = data_lancamento
            ret.product_id = products_map[product_code].id
          end
          
          stats[:returns] = (stats[:returns] || 0) + 1
        else
          # Casos não classificados - tratar como troca por padrão
          exchange_external_id = "#{year_info[:year]}_#{store_config[:external_id]}_exchange_#{documento}_#{row['ordem']}"
          
          exchange = Exchange.find_or_create_by!(external_id: exchange_external_id) do |ex|
            ex.voucher_number = documento
            ex.voucher_value = unit_price.abs
            ex.original_document = documento
            ex.customer_code = row['codigo_cliente']
            ex.exchange_type = 'OUTROS'
            ex.is_credit = true
            ex.processed_at = data_lancamento
            ex.seller_id = sellers_map[seller_key].id
          end
          
          stats[:exchanges] = (stats[:exchanges] || 0) + 1
        end
        
        stats[:total_value] += total_amount # Já é negativo
      elsif is_transfer
        # Pular transferências por enquanto
        next
      else
        # Criar item do pedido normal (venda)
        order = orders_map[order_key]
        product = products_map[product_code]
        
        item_external_id = "#{year_info[:year]}_#{store_config[:external_id]}_#{documento}_#{product_code}_#{row['ordem']}"
        
        unit_price = parse_br_money(row['preco_unitario'])
        quantity = row['quantidade'].to_i
        
        item = OrderItem.find_or_create_by!(external_id: item_external_id) do |item|
          item.order_id = order.id
          item.product_id = product.id
          item.quantity = quantity
          item.unit_price = unit_price
          item.store_id = store.id
        end
        
        if item.id_previously_changed?
          stats[:items] += 1
          stats[:total_value] += (quantity * unit_price)
        end
      end
    end
    
    log_progress("     ✅ #{year_info[:year]}: #{year_rows} linhas, #{year_sales} vendas, #{stats[:returns]} devoluções, #{stats[:exchanges]} trocas processadas", log_file)
    
    # 4. ESTATÍSTICAS FINAIS
    log_progress("🎉 Importação completa de dados 2025 da loja Iguatemi SP concluída!", log_file)
    log_progress("📊 Estatísticas da importação:", log_file)
    log_progress("   - Loja: #{store.name}", log_file)
    log_progress("   - Vendedores novos: #{stats[:sellers]}", log_file)
    log_progress("   - Produtos novos: #{stats[:products]}", log_file)
    log_progress("   - Pedidos: #{stats[:orders]}", log_file)
    log_progress("   - Itens vendidos: #{stats[:items]}", log_file)
    log_progress("   - Devoluções: #{stats[:returns]}", log_file)
    log_progress("   - Trocas: #{stats[:exchanges]}", log_file)
    log_progress("   - Valor líquido: R$ #{stats[:total_value].round(2)}", log_file)
    
    # Verificação final dos dados carregados
    total_orders_2025 = Order.joins(:seller)
                             .where(sellers: { store_id: store.id })
                             .where('EXTRACT(year FROM sold_at) = ?', 2025)
                             .count
    
    total_items_2025 = OrderItem.joins(order: :seller)
                                .where(sellers: { store_id: store.id })
                                .where('EXTRACT(year FROM orders.sold_at) = ?', 2025)
                                .count
    
    total_value_2025 = OrderItem.joins(order: :seller)
                                .where(sellers: { store_id: store.id })
                                .where('EXTRACT(year FROM orders.sold_at) = ?', 2025)
                                .sum('order_items.quantity * order_items.unit_price')
    
    # Contar trocas de 2025
    total_exchanges_2025 = Exchange.joins(:seller)
                                   .where(sellers: { store_id: store.id })
                                   .where('EXTRACT(year FROM processed_at) = ?', 2025)
                                   .count
    
    total_exchanges_value = Exchange.joins(:seller)
                                    .where(sellers: { store_id: store.id })
                                    .where('EXTRACT(year FROM processed_at) = ?', 2025)
                                    .sum(:voucher_value)
    
    # Contar devoluções de 2025
    total_returns_2025 = Return.joins(original_order: :seller)
                               .where(sellers: { store_id: store.id })
                               .where('EXTRACT(year FROM processed_at) = ?', 2025)
                               .count
    
    log_progress("\n📊 Dados finais de 2025 na base:", log_file)
    log_progress("   - Pedidos: #{total_orders_2025}", log_file)
    log_progress("   - Itens: #{total_items_2025}", log_file)
    log_progress("   - Valor vendas: R$ #{total_value_2025.round(2)}", log_file)
    log_progress("   - Trocas: #{total_exchanges_2025} (R$ #{total_exchanges_value.round(2)})", log_file)
    log_progress("   - Devoluções: #{total_returns_2025}", log_file)
    
    puts "\n✅ Importação concluída com sucesso!"
    puts "📈 Dados de 2025 da loja Iguatemi SP estão prontos para análise"
    puts "🔄 Incluindo vendas, trocas e devoluções"
  end
end
