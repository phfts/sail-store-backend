require 'csv'

namespace :import do
  desc "Import SOUQ Iguatemi SP data for 2025 with CLEAN external_ids (no prefixes/suffixes)"
  task souq_iguatemi_clean_ids: :environment do
    # Setup do arquivo de log
    log_file = Rails.root.join('log', 'souq_iguatemi_clean_ids_import.log')
    File.delete(log_file) if File.exist?(log_file)
    
    def log_progress(message, log_file_path)
      timestamp = Time.current.strftime("%H:%M:%S")
      log_message = "[#{timestamp}] #{message}"
      puts log_message
      File.open(log_file_path, 'a') { |f| f.puts log_message }
    end
    
    log_progress("🚀 Importação SOUQ Iguatemi SP - Com external_ids LIMPOS iniciada...", log_file)
    log_progress("   📅 Período: 2025", log_file)
    log_progress("   🏪 Loja: SOUQ - SP - IGUATEMI SP", log_file)
    log_progress("   🧹 EXTERNAL_IDS LIMPOS: sem prefixos ou sufixos", log_file)
    
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
    
    def load_sellers_from_file(data_path)
      sellers_file = File.join(data_path, 'LinxVendedores_store=16945787002148_historical.csv')
      sellers_map = {}
      
      if File.exist?(sellers_file)
        puts "📋 Carregando vendedores do arquivo LinxVendedores..."
        CSV.foreach(sellers_file, headers: true, encoding: 'UTF-8') do |row|
          cod_vendedor = row['cod_vendedor']&.strip
          nome_vendedor = row['nome_vendedor']&.strip
          
          if cod_vendedor && nome_vendedor && !nome_vendedor.empty?
            sellers_map[cod_vendedor] = nome_vendedor
          end
        end
        puts "✅ #{sellers_map.count} vendedores carregados do arquivo"
      else
        puts "⚠️ Arquivo LinxVendedores não encontrado, usando extração da coluna obs"
      end
      
      sellers_map
    end
    
    # FUNÇÃO PARA LIMPAR EXTERNAL_ID
    def clean_external_id(value)
      return nil if value.blank?
      # Remove tudo que não for número
      clean_id = value.to_s.gsub(/[^0-9]/, '')
      return nil if clean_id.blank?
      clean_id
    end
    
    # 1. CRIAR ESTRUTURA BÁSICA
    log_progress("🏗️ Criando estrutura básica...", log_file)
    
    # Criar empresa
    company = Company.find_or_create_by!(name: "SOUQ") do |c|
      c.slug = "souq"
      c.description = "Rede de lojas Souq"
    end
    log_progress("✅ Empresa: #{company.name} (ID: #{company.id})", log_file)
    
    # Criar loja
    store = Store.find_or_create_by!(cnpj: store_config[:cnpj], company_id: company.id) do |s|
      s.name = store_config[:name]
      s.external_id = store_config[:external_id]
      s.slug = "souq-sp-iguatemi-sp"
    end
    log_progress("✅ Loja: #{store.name} (ID: #{store.id})", log_file)
    
    # Criar categoria
    category = Category.find_or_create_by!(company_id: company.id) do |cat|
      cat.name = "Outros"
      cat.external_id = "outros"
    end
    log_progress("✅ Categoria: #{category.name} (ID: #{category.id})", log_file)
    
    # 2. PROCESSAR DADOS DE 2025
    log_progress("📁 Processando dados de 2025...", log_file)
    
    # Mapas para evitar duplicatas
    sellers_map = {}
    products_map = {}
    orders_map = {}
    
    # Configuração para 2025
    year_info = { year: 2025, file_suffix: "2025-01-01_endDate=2025-08-12" }
    
    movement_file = "#{store_config[:data_path]}/LinxMovimento_store=#{store_config[:cnpj]}_beginDate=#{year_info[:file_suffix]}.csv"
    
    unless File.exist?(movement_file)
      log_progress("❌ Arquivo não encontrado: #{movement_file}", log_file)
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
    
    log_progress("📁 Processando arquivo: #{movement_file}", log_file)
    
    # 2. CARREGAMENTO DE VENDEDORES
    vendors_names_map = load_sellers_from_file(store_config[:data_path])
    
    CSV.foreach(movement_file, headers: true, encoding: 'UTF-8') do |row|
      year_rows += 1
      operacao = row['operacao']&.strip
      
      # Processar vendas (S), devoluções (D) e combinações (DS, etc.)
      next unless operacao&.include?('S') || operacao&.include?('D') || operacao&.strip == 'E'
      next if row['cancelado'] == 'S' # Pular cancelados
      
      # Verificar ano
      data_lancamento = parse_br_date(row['data_lancamento'])
      next unless data_lancamento && data_lancamento.year == year_info[:year]
      
      # Determinar tipo da operação
      is_return_or_exchange = operacao&.include?('D')
      is_transfer = operacao&.strip == 'E'
      
      # Contar apenas vendas reais, não devoluções
      unless is_return_or_exchange || is_transfer
        year_sales += 1
        
        # Progress indicator
        if year_sales % 1000 == 0
          log_progress("     📦 #{year_sales} vendas processadas...", log_file)
        end
      end
      
      # Criar/encontrar vendedor com external_id LIMPO
      seller_code = clean_external_id(row['cod_vendedor'])
      next if seller_code.blank?
      
      unless sellers_map[seller_code]
        # Priorizar nome do arquivo LinxVendedores, depois obs, por último fallback
        seller_name = vendors_names_map[seller_code] || 
                     extract_seller_name(row['obs']) || 
                     "Vendedor #{seller_code}"
        
        # Nome único por loja
        unique_name = seller_name
        counter = 1
        while Seller.exists?(name: unique_name, store_id: store.id)
          unique_name = "#{seller_name} (#{counter})"
          counter += 1
        end
        
        seller = Seller.create!(
          external_id: seller_code, # LIMPO: apenas números
          company_id: company.id,
          name: unique_name,
          store_id: store.id
        )
        
        sellers_map[seller_code] = seller
        stats[:sellers] += 1
        log_progress("     👤 Novo vendedor: #{seller.name} (external_id: #{seller.external_id})", log_file)
      end
      
      # Criar/encontrar produto com external_id LIMPO
      product_code = clean_external_id(row['cod_produto'])
      next if product_code.blank?
      
      unless products_map[product_code]
        product = Product.find_or_create_by!(external_id: product_code) do |p| # LIMPO: apenas números
          p.name = "Produto #{product_code}"
          p.sku = row['cod_barra'] || product_code
          p.category_id = category.id
        end
        products_map[product_code] = product
        stats[:products] += 1 if product.id_previously_changed?
      end
      
      # Criar/encontrar pedido com external_id LIMPO
      documento = clean_external_id(row['documento'])
      next if documento.blank?
      
      order_key = "#{documento}_#{data_lancamento.strftime('%Y%m%d')}"
      unless orders_map[order_key]
        order_external_id = documento # COMPLETAMENTE LIMPO: apenas o documento
        
        order = Order.find_or_create_by!(external_id: order_external_id) do |o|
          o.seller_id = sellers_map[seller_code].id
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
          exchange_external_id = clean_external_id("#{documento}_exchange_#{row['ordem']}")
          
          exchange = Exchange.find_or_create_by!(external_id: exchange_external_id) do |ex|
            ex.voucher_number = documento
            ex.voucher_value = unit_price.abs # Valor positivo para voucher
            ex.original_document = documento
            ex.customer_code = row['codigo_cliente']
            ex.exchange_type = 'TROCA SIMPLES'
            ex.is_credit = true # Crédito para o cliente
            ex.processed_at = data_lancamento
            ex.seller_id = sellers_map[seller_code].id
          end
          
          stats[:exchanges] = (stats[:exchanges] || 0) + 1
        elsif is_return
          # Criar Return
          return_external_id = clean_external_id("#{documento}_return_#{product_code}_#{row['ordem']}")
          
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
          exchange_external_id = clean_external_id("#{documento}_exchange_#{row['ordem']}")
          
          exchange = Exchange.find_or_create_by!(external_id: exchange_external_id) do |ex|
            ex.voucher_number = documento
            ex.voucher_value = unit_price.abs
            ex.original_document = documento
            ex.customer_code = row['codigo_cliente']
            ex.exchange_type = 'OUTROS'
            ex.is_credit = true
            ex.processed_at = data_lancamento
            ex.seller_id = sellers_map[seller_code].id
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
        
        item_external_id = "#{documento}_#{product_code}_#{row['ordem']}" # COMPLETAMENTE LIMPO
        
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
    
    log_progress("✅ #{year_info[:year]}: #{year_rows} linhas, #{year_sales} vendas, #{stats[:returns]} devoluções, #{stats[:exchanges]} trocas processadas", log_file)
    
    # 3. ESTATÍSTICAS FINAIS
    log_progress("🎉 Importação com external_ids LIMPOS concluída!", log_file)
    log_progress("📊 Estatísticas da importação:", log_file)
    log_progress("   - Loja: #{store.name}", log_file)
    log_progress("   - Vendedores novos: #{stats[:sellers]}", log_file)
    log_progress("   - Produtos novos: #{stats[:products]}", log_file)
    log_progress("   - Pedidos: #{stats[:orders]}", log_file)
    log_progress("   - Itens vendidos: #{stats[:items]}", log_file)
    log_progress("   - Devoluções: #{stats[:returns]}", log_file)
    log_progress("   - Trocas: #{stats[:exchanges]}", log_file)
    log_progress("   - Valor líquido: R$ #{stats[:total_value].round(2)}", log_file)
    
    # Verificação final
    total_orders = Order.joins(:seller).where(sellers: { store_id: store.id }).count
    total_items = OrderItem.joins(order: :seller).where(sellers: { store_id: store.id }).count
    total_value = OrderItem.joins(order: :seller).where(sellers: { store_id: store.id }).sum('order_items.quantity * order_items.unit_price')
    
    # Contar trocas
    total_exchanges = Exchange.joins(:seller).where(sellers: { store_id: store.id }).count
    total_exchanges_value = Exchange.joins(:seller).where(sellers: { store_id: store.id }).sum(:voucher_value)
    
    # Contar devoluções
    total_returns = Return.joins(product: :category).where(categories: { company_id: company.id }).count
    
    log_progress("\n📊 Dados finais na base:", log_file)
    log_progress("   - Pedidos: #{total_orders}", log_file)
    log_progress("   - Itens: #{total_items}", log_file)
    log_progress("   - Valor vendas: R$ #{total_value.round(2)}", log_file)
    log_progress("   - Trocas: #{total_exchanges} (R$ #{total_exchanges_value.round(2)})", log_file)
    log_progress("   - Devoluções: #{total_returns}", log_file)
    
    puts "\n✅ Importação com external_ids LIMPOS concluída com sucesso!"
    puts "🧹 Todos os external_ids foram limpos (apenas números)"
  end
end
