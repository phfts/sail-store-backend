require 'csv'

namespace :import do
  desc "Import all SOUQ stores data with complete historical data (2023-2025)"
  task souq_complete: :environment do
    # Setup do arquivo de log
    log_file = Rails.root.join('log', 'souq_import.log')
    File.delete(log_file) if File.exist?(log_file)
    
    def log_progress(message, log_file_path)
      timestamp = Time.current.strftime("%H:%M:%S")
      log_message = "[#{timestamp}] #{message}"
      puts log_message
      File.open(log_file_path, 'a') { |f| f.puts log_message }
    end
    
    log_progress("🚀 Importação completa da rede SOUQ iniciada...", log_file)
    log_progress("   📅 Histórico: 2023, 2024, 2025", log_file)
    log_progress("   🏪 Lojas: Pátio Higienópolis + Iguatemi SP", log_file)
    log_progress("   📝 Acompanhe o progresso em: #{log_file}", log_file)
    
    # Configuração das lojas
    stores_config = [
      {
        cnpj: "16945787001508",
        name: "SOUQ - SP - PÁTIO HIGIENÓPOLIS", 
        external_id: "higienopolis",
        data_path: "/home/paulo/work/sail/analysis/data/souq/SOUQ_-_SP_-_PÁTIO_HIGIENÓPOLIS/dados"
      },
      {
        cnpj: "16945787002148",
        name: "SOUQ - SP - IGUATEMI SP",
        external_id: "iguatemi_sp", 
        data_path: "/home/paulo/work/sail/analysis/data/souq/SOUQ_-_SP_-_IGUATEMI_SP/dados"
      }
    ]
    
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
    
    # 1. LIMPEZA DOS DADOS ATUAIS
    log_progress("🧹 Limpando dados existentes da Souq...", log_file)
    
    # Deletar dados relacionados à empresa Souq
    souq_companies = Company.where(name: ["Souq", "SOUQ"])
    souq_companies.each do |company|
      log_progress("   🗑️  Deletando dados da empresa: #{company.name}", log_file)
      
      # Deletar em cascata respeitando foreign keys
      company.stores.each do |store|
        log_progress("     - Loja: #{store.name}", log_file)
        OrderItem.where(store_id: store.id).delete_all
        Order.joins(:seller).where(sellers: { store_id: store.id }).delete_all
        store.sellers.delete_all
      end
      
      company.stores.delete_all
      Category.where(company_id: company.id).delete_all
      company.delete
    end
    
    log_progress("✅ Limpeza concluída!", log_file)
    
    # 2. CRIAR EMPRESA SOUQ ÚNICA
    log_progress("🏢 Criando empresa Souq...", log_file)
    company = Company.create!(
      name: "Souq",
      active: true,
      description: "Rede de lojas Souq - Todas as unidades"
    )
    log_progress("✅ Empresa criada: #{company.name} (ID: #{company.id})", log_file)
    
    # 3. CRIAR CATEGORIA PADRÃO
    category = Category.create!(
      name: "Produtos Souq",
      company_id: company.id,
      external_id: "souq_products"
    )
    log_progress("✅ Categoria criada: #{category.name}", log_file)
    
    # 4. PROCESSAR CADA LOJA
    total_stats = {
      stores: 0,
      sellers: 0,
      products: 0,
      orders: 0,
      items: 0,
      total_value: 0.0
    }
    
    stores_config.each do |store_config|
      log_progress("🏪 Processando loja: #{store_config[:name]}", log_file)
      
      # Criar loja
      store = Store.create!(
        cnpj: store_config[:cnpj],
        name: store_config[:name],
        external_id: store_config[:external_id],
        company_id: company.id
      )
      log_progress("✅ Loja criada: #{store.name} (ID: #{store.id})", log_file)
      total_stats[:stores] += 1
      
      # Mapas para evitar duplicatas
      sellers_map = {}
      products_map = {}
      orders_map = {}
      
      # Anos para processar
      years_data = [
        { year: 2023, file_suffix: "2023-01-01_endDate=2023-12-31" },
        { year: 2024, file_suffix: "2024-01-01_endDate=2024-12-31" },
        { year: 2025, file_suffix: "2025-01-01_endDate=2025-08-12" }
      ]
      
      years_data.each do |year_info|
        log_progress("   📅 Processando ano #{year_info[:year]}...", log_file)
        
        movement_file = "#{store_config[:data_path]}/LinxMovimento_store=#{store_config[:cnpj]}_beginDate=#{year_info[:file_suffix]}.csv"
        
        unless File.exist?(movement_file)
          log_progress("     ⚠️  Arquivo não encontrado, pulando...", log_file)
          next
        end
        
        year_sales = 0
        year_rows = 0
        
        CSV.foreach(movement_file, headers: true, encoding: 'UTF-8') do |row|
          year_rows += 1
          operacao = row['operacao']&.strip
          
          next unless operacao == 'S' # Apenas vendas
          next if row['cancelado'] == 'S' # Pular cancelados
          
          # Verificar ano
          data_lancamento = parse_br_date(row['data_lancamento'])
          next unless data_lancamento && data_lancamento.year == year_info[:year]
          
          year_sales += 1
          
          # Progress indicator
          if year_sales % 2000 == 0
            log_progress("     📦 #{year_sales} vendas processadas...", log_file)
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
            total_stats[:sellers] += 1
            
            if year_info[:year] == 2025 # Log apenas para o ano mais recente
              log_progress("     👤 Vendedor: #{seller.name}", log_file)
            end
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
            total_stats[:products] += 1 if product.id_previously_changed?
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
            total_stats[:orders] += 1 if order.id_previously_changed?
          end
          
          # Criar item do pedido
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
            total_stats[:items] += 1
            total_stats[:total_value] += (quantity * unit_price)
          end
        end
        
        log_progress("     ✅ #{year_info[:year]}: #{year_rows} linhas, #{year_sales} vendas", log_file)
      end
      
      log_progress("   ✅ Loja #{store.name} concluída!", log_file)
    end
    
    # 5. ESTATÍSTICAS FINAIS
    log_progress("🎉 Importação completa da rede Souq concluída!", log_file)
    log_progress("📊 Estatísticas gerais:", log_file)
    log_progress("   - Empresa: #{company.name}", log_file)
    log_progress("   - Lojas: #{total_stats[:stores]}", log_file)
    log_progress("   - Vendedores: #{total_stats[:sellers]}", log_file)
    log_progress("   - Produtos únicos: #{total_stats[:products]}", log_file)
    log_progress("   - Pedidos: #{total_stats[:orders]}", log_file)
    log_progress("   - Itens vendidos: #{total_stats[:items]}", log_file)
    log_progress("   - Valor total: R$ #{total_stats[:total_value].round(2)}", log_file)
    
    puts "\n📅 Dados por ano e loja:"
    [2023, 2024, 2025].each do |year|
      puts "   #{year}:"
      stores_config.each do |store_config|
        store = Store.find_by(cnpj: store_config[:cnpj])
        next unless store
        
        year_orders = Order.joins(:seller)
                           .where(sellers: { store_id: store.id })
                           .where('EXTRACT(year FROM sold_at) = ?', year)
        year_items = OrderItem.joins(order: :seller)
                             .where(sellers: { store_id: store.id })
                             .where('EXTRACT(year FROM orders.sold_at) = ?', year)
        year_value = year_items.sum('order_items.quantity * order_items.unit_price')
        
        puts "     #{store.name}: #{year_orders.count} pedidos, #{year_items.count} itens, R$ #{year_value.round(2)}"
      end
    end
    
    puts "\n🎯 Dados disponíveis para:"
    puts "   - Análises de performance por loja"
    puts "   - Comparação histórica 2023-2025"
    puts "   - KPIs individuais por vendedor"
    puts "   - Dashboards de vendas por período"
    puts "   - Metas e comissões"
  end
end
