namespace :souq do
  desc "Faz backup dos dados SOUQ para upload no Heroku"
  task backup_data: :environment do
    puts "📦 CRIANDO BACKUP DOS DADOS SOUQ"
    puts "=" * 50
    
    # Criar diretório de backup
    backup_dir = Rails.root.join('tmp', 'souq_backup')
    FileUtils.mkdir_p(backup_dir)
    
    # Buscar empresa SOUQ
    souq_company = Company.find_by(name: 'SOUQ')
    unless souq_company
      puts "❌ Empresa SOUQ não encontrada"
      exit 1
    end
    
    puts "🏢 Empresa encontrada: #{souq_company.name} (ID: #{souq_company.id})"
    
    # Buscar loja
    souq_store = souq_company.stores.first
    unless souq_store
      puts "❌ Loja da SOUQ não encontrada"
      exit 1
    end
    
    puts "🏪 Loja encontrada: #{souq_store.name} (ID: #{souq_store.id})"
    
    # Buscar categoria
    outros_category = souq_company.categories.find_by(external_id: 'outros')
    unless outros_category
      puts "❌ Categoria 'Outros' não encontrada"
      exit 1
    end
    
    puts "📂 Categoria encontrada: #{outros_category.name} (ID: #{outros_category.id})"
    
    # Exportar dados
    export_company_data(souq_company, backup_dir)
    export_store_data(souq_store, backup_dir)
    export_category_data(outros_category, backup_dir)
    export_sellers_data(souq_company, backup_dir)
    export_products_data(outros_category, backup_dir)
    export_orders_data(souq_company, backup_dir)
    export_exchanges_data(souq_company, backup_dir)
    export_returns_data(souq_company, backup_dir)
    
    puts "\n🎉 Backup criado em: #{backup_dir}"
    puts "\n📋 Arquivos criados:"
    Dir[backup_dir.join('*.json')].each do |file|
      size = File.size(file) / 1024.0
      puts "  - #{File.basename(file)} (#{size.round(2)} KB)"
    end
  end
  
  desc "Restaura dados SOUQ do backup (modo seguro para produção)"
  task restore_data: :environment do
    puts "📥 RESTAURANDO DADOS SOUQ DO BACKUP"
    puts "=" * 50
    
    backup_dir = Rails.root.join('tmp', 'souq_backup')
    
    unless Dir.exist?(backup_dir)
      puts "❌ Diretório de backup não encontrado: #{backup_dir}"
      puts "💡 Execute primeiro: rails souq:backup_data"
      exit 1
    end
    
    # Verificar se estamos em produção
    if Rails.env.production?
      puts "⚠️  MODO PRODUÇÃO DETECTADO"
      puts "🔒 Usando modo seguro (não sobrescreve dados existentes)"
      puts "📊 Exibindo estatísticas antes da importação:"
      show_current_stats
      puts ""
    end
    
    # Restaurar na ordem correta
    restore_company_data(backup_dir)
    restore_store_data(backup_dir)
    restore_category_data(backup_dir)
    restore_sellers_data(backup_dir)
    restore_products_data(backup_dir)
    restore_orders_data(backup_dir)
    
    puts "\n🎉 RESTAURAÇÃO CONCLUÍDA COM SUCESSO!"
    
    if Rails.env.production?
      puts "\n📊 Estatísticas após importação:"
      show_current_stats
    end
  end
  
  desc "Atualiza dados SOUQ incrementalmente (seguro para produção)"
  task update_data: :environment do
    puts "🔄 ATUALIZAÇÃO INCREMENTAL DOS DADOS SOUQ"
    puts "=" * 50
    
    backup_dir = Rails.root.join('tmp', 'souq_backup')
    
    unless Dir.exist?(backup_dir)
      puts "❌ Diretório de backup não encontrado: #{backup_dir}"
      puts "💡 Execute primeiro: rails souq:backup_data"
      exit 1
    end
    
    puts "📊 Estado atual da base de dados:"
    show_current_stats
    puts ""
    
    # Só importa dados novos, nunca sobrescreve
    incremental_restore_data(backup_dir)
    
    puts "\n🎉 ATUALIZAÇÃO INCREMENTAL CONCLUÍDA!"
    puts "\n📊 Estado final da base de dados:"
    show_current_stats
  end
  
  desc "Transferir arquivos de backup para produção via git"
  task prepare_production_transfer: :environment do
    puts "📦 PREPARANDO TRANSFERÊNCIA PARA PRODUÇÃO"
    puts "=" * 50
    
    backup_dir = Rails.root.join('tmp', 'souq_backup')
    production_dir = Rails.root.join('db', 'souq_data')
    
    unless Dir.exist?(backup_dir)
      puts "❌ Diretório de backup não encontrado"
      puts "💡 Execute primeiro: rails souq:backup_data"
      exit 1
    end
    
    # Criar diretório na estrutura do projeto
    FileUtils.mkdir_p(production_dir)
    
    # Copiar arquivos de backup
    Dir[backup_dir.join('*.json')].each do |file|
      FileUtils.cp(file, production_dir)
      puts "📋 Copiado: #{File.basename(file)}"
    end
    
    puts "\n✅ Arquivos prontos para commit em: #{production_dir}"
    puts "\n🚀 Próximos passos:"
    puts "1. git add db/souq_data/"
    puts "2. git commit -m 'Add SOUQ production data backup'"
    puts "3. git push heroku main"
    puts "4. heroku run rails souq:restore_from_production_data"
  end
  
  desc "Restaura dados do diretório de produção (db/souq_data)"
  task restore_from_production_data: :environment do
    puts "📥 RESTAURANDO DADOS DA PRODUÇÃO"
    puts "=" * 50
    
    production_dir = Rails.root.join('db', 'souq_data')
    
    unless Dir.exist?(production_dir)
      puts "❌ Diretório de dados de produção não encontrado: #{production_dir}"
      exit 1
    end
    
    puts "📊 Estado atual:"
    show_current_stats
    puts ""
    
    # Usar o diretório de produção
    restore_company_data(production_dir)
    restore_store_data(production_dir)
    restore_category_data(production_dir)
    restore_sellers_data(production_dir)
    restore_products_data(production_dir)
    restore_orders_data(production_dir)
    
    puts "\n🎉 DADOS DE PRODUÇÃO RESTAURADOS!"
    puts "\n📊 Estado final:"
    show_current_stats
  end
  
  private
  
  def show_current_stats
    companies = Company.count
    stores = Store.count
    categories = Category.count
    sellers = Seller.count
    products = Product.count
    orders = Order.count
    order_items = OrderItem.count
    
    puts "🏢 Empresas: #{companies}"
    puts "🏪 Lojas: #{stores}"
    puts "📂 Categorias: #{categories}"
    puts "👥 Vendedores: #{sellers}"
    puts "📦 Produtos: #{products}"
    puts "🛒 Vendas: #{orders}"
    puts "📋 Itens de venda: #{order_items}"
  end
  
  def incremental_restore_data(backup_dir)
    puts "🔄 Modo incremental: só adiciona dados novos"
    
    # Usar métodos mais seguros que nunca sobrescrevem
    safe_restore_company_data(backup_dir)
    safe_restore_store_data(backup_dir)
    safe_restore_category_data(backup_dir)
    safe_restore_sellers_data(backup_dir)
    safe_restore_products_data(backup_dir)
    safe_restore_orders_data(backup_dir)
  end
  
  def safe_restore_company_data(backup_dir)
    puts "\n📥 Verificando empresa SOUQ..."
    
    file_path = backup_dir.join('01_company.json')
    return unless File.exist?(file_path)
    
    company_data = JSON.parse(File.read(file_path))
    
    @souq_company = Company.find_by(name: company_data['name'])
    
    if @souq_company
      puts "✅ Empresa SOUQ já existe (ID: #{@souq_company.id})"
    else
      @souq_company = Company.create!(
        name: company_data['name'],
        active: company_data['active'],
        description: company_data['description'],
        simplified_frontend: company_data['simplified_frontend']
      )
      puts "🆕 Empresa SOUQ criada (ID: #{@souq_company.id})"
    end
  end
  
  def safe_restore_store_data(backup_dir)
    puts "\n📥 Verificando loja PÁTIO HIGIENÓPOLIS..."
    
    file_path = backup_dir.join('02_store.json')
    return unless File.exist?(file_path)
    
    store_data = JSON.parse(File.read(file_path))
    
    @souq_store = Store.find_by(
      company_id: @souq_company.id,
      name: store_data['name']
    )
    
    if @souq_store
      puts "✅ Loja já existe (ID: #{@souq_store.id})"
    else
      @souq_store = Store.create!(
        company_id: @souq_company.id,
        name: store_data['name'],
        cnpj: store_data['cnpj'],
        address: store_data['address']
      )
      puts "🆕 Loja criada (ID: #{@souq_store.id})"
    end
  end
  
  def safe_restore_category_data(backup_dir)
    puts "\n📥 Verificando categoria Outros..."
    
    file_path = backup_dir.join('03_category.json')
    return unless File.exist?(file_path)
    
    category_data = JSON.parse(File.read(file_path))
    
    @outros_category = Category.find_or_create_by(
      company_id: @souq_company.id,
      external_id: category_data['external_id']
    ) do |cat|
      cat.name = category_data['name']
    end
    
    puts "✅ Categoria: #{@outros_category.name} (ID: #{@outros_category.id})"
  end
  
  def safe_restore_sellers_data(backup_dir)
    puts "\n📥 Importando vendedores (só novos)..."
    
    file_path = backup_dir.join('04_sellers.json')
    return unless File.exist?(file_path)
    
    sellers_data = JSON.parse(File.read(file_path))
    created_count = 0
    skipped_count = 0
    
    sellers_data.each do |seller_data|
      existing_seller = Seller.find_by(
        company_id: @souq_company.id,
        external_id: seller_data['external_id']
      )
      
      if existing_seller
        skipped_count += 1
      else
        Seller.create!(
          company_id: @souq_company.id,
          store_id: @souq_store.id,
          name: seller_data['name'],
          external_id: seller_data['external_id'],
          email: seller_data['email'],
          whatsapp: seller_data['whatsapp'],
          store_admin: seller_data['store_admin']
        )
        created_count += 1
      end
    end
    
    puts "✅ Vendedores: #{created_count} novos, #{skipped_count} já existiam"
  end
  
  def safe_restore_products_data(backup_dir)
    puts "\n📥 Importando produtos (só novos)..."
    
    file_path = backup_dir.join('05_products.json')
    return unless File.exist?(file_path)
    
    products_data = JSON.parse(File.read(file_path))
    created_count = 0
    skipped_count = 0
    
    products_data.each do |product_data|
      existing_product = Product.find_by(external_id: product_data['external_id'])
      
      if existing_product
        skipped_count += 1
      else
        Product.create!(
          category_id: @outros_category.id,
          external_id: product_data['external_id'],
          name: product_data['name'],
          sku: product_data['sku']
        )
        created_count += 1
      end
    end
    
    puts "✅ Produtos: #{created_count} novos, #{skipped_count} já existiam"
  end
  
  def safe_restore_orders_data(backup_dir)
    puts "\n📥 Importando vendas (só novas)..."
    
    file_path = backup_dir.join('06_orders.json')
    return unless File.exist?(file_path)
    
    orders_data = JSON.parse(File.read(file_path))
    created_orders = 0
    created_items = 0
    skipped_orders = 0
    
    orders_data.each do |order_data|
      existing_order = Order.find_by(external_id: order_data['external_id'])
      
      if existing_order
        skipped_orders += 1
        next
      end
      
      # Buscar seller pelo external_id na empresa SOUQ
      seller = Seller.find_by(
        company_id: @souq_company.id,
        external_id: order_data['seller_id']
      )
      
      next unless seller
      
      order = Order.create!(
        seller_id: seller.id,
        external_id: order_data['external_id'],
        sold_at: order_data['sold_at']
      )
      created_orders += 1
      
      # Criar itens da venda
      order_data['order_items'].each do |item_data|
        product = Product.find_by(external_id: item_data['product_id'])
        next unless product
        
        OrderItem.create!(
          order_id: order.id,
          product_id: product.id,
          store_id: @souq_store.id,
          quantity: item_data['quantity'],
          unit_price: item_data['unit_price'],
          external_id: item_data['external_id']
        )
        created_items += 1
      end
    end
    
    puts "✅ Vendas: #{created_orders} novas, #{skipped_orders} já existiam"
    puts "✅ Itens: #{created_items} novos"
  end
  
  def export_exchanges_data(company, backup_dir)
    puts "\n📤 Exportando trocas..."
    
    exchanges = Exchange.limit(100)
                       .map do |exchange|
      {
        id: exchange.id,
        seller_id: exchange.seller_id,
        external_id: exchange.external_id,
        exchange_type: exchange.exchange_type,
        processed_at: exchange.processed_at,
        voucher_number: exchange.voucher_number,
        voucher_value: exchange.voucher_value
      }
    end
    
    File.write(
      backup_dir.join('07_exchanges.json'),
      JSON.pretty_generate(exchanges)
    )
    
    puts "✅ #{exchanges.count} trocas exportadas (limitado a 100 para teste)"
  end
  
  def export_returns_data(company, backup_dir)
    puts "\n📤 Exportando devoluções..."
    
    returns = Return.limit(100)
                    .map do |return_record|
      {
        id: return_record.id,
        original_order_id: return_record.original_order_id,
        product_id: return_record.product_id,
        external_id: return_record.external_id,
        return_transaction: return_record.return_transaction,
        quantity_returned: return_record.quantity_returned,
        processed_at: return_record.processed_at,
        original_sale_id: return_record.original_sale_id
      }
    end
    
    File.write(
      backup_dir.join('08_returns.json'),
      JSON.pretty_generate(returns)
    )
    
    puts "✅ #{returns.count} devoluções exportadas (limitado a 100 para teste)"
  end
  
  def export_company_data(company, backup_dir)
    puts "\n📤 Exportando dados da empresa..."
    
    company_data = {
      id: company.id,
      name: company.name,
      active: company.active,
      description: company.description,
      simplified_frontend: company.simplified_frontend,
      slug: company.slug
    }
    
    File.write(
      backup_dir.join('01_company.json'),
      JSON.pretty_generate(company_data)
    )
    
    puts "✅ Empresa exportada"
  end
  
  def export_store_data(store, backup_dir)
    puts "\n📤 Exportando dados da loja..."
    
    store_data = {
      id: store.id,
      company_id: store.company_id,
      name: store.name,
      cnpj: store.cnpj,
      address: store.address,
      slug: store.slug
    }
    
    File.write(
      backup_dir.join('02_store.json'),
      JSON.pretty_generate(store_data)
    )
    
    puts "✅ Loja exportada"
  end
  
  def export_category_data(category, backup_dir)
    puts "\n📤 Exportando dados da categoria..."
    
    category_data = {
      id: category.id,
      company_id: category.company_id,
      name: category.name,
      external_id: category.external_id
    }
    
    File.write(
      backup_dir.join('03_category.json'),
      JSON.pretty_generate(category_data)
    )
    
    puts "✅ Categoria exportada"
  end
  
  def export_sellers_data(company, backup_dir)
    puts "\n📤 Exportando vendedores..."
    
    sellers = company.sellers.map do |seller|
      {
        id: seller.id,
        company_id: seller.company_id,
        store_id: seller.store_id,
        name: seller.name,
        external_id: seller.external_id,
        email: seller.email,
        whatsapp: seller.whatsapp,
        store_admin: seller.store_admin
      }
    end
    
    File.write(
      backup_dir.join('04_sellers.json'),
      JSON.pretty_generate(sellers)
    )
    
    puts "✅ #{sellers.count} vendedores exportados"
  end
  
  def export_products_data(category, backup_dir)
    puts "\n📤 Exportando produtos..."
    
    products = category.products.limit(1000).map do |product|
      {
        id: product.id,
        category_id: product.category_id,
        name: product.name,
        external_id: product.external_id,
        sku: product.sku
      }
    end
    
    File.write(
      backup_dir.join('05_products.json'),
      JSON.pretty_generate(products)
    )
    
    puts "✅ #{products.count} produtos exportados (limitado a 1000 para teste)"
  end
  
  def export_orders_data(company, backup_dir)
    puts "\n📤 Exportando vendas..."
    
    orders = Order.joins(:seller)
                  .where(seller: { company_id: company.id })
                  .includes(:order_items)
                  .limit(100)
                  .map do |order|
      {
        id: order.id,
        seller_id: order.seller_id,
        external_id: order.external_id,
        sold_at: order.sold_at,
        order_items: order.order_items.map do |item|
          {
            id: item.id,
            order_id: item.order_id,
            product_id: item.product_id,
            store_id: item.store_id,
            quantity: item.quantity,
            unit_price: item.unit_price,
            external_id: item.external_id
          }
        end
      }
    end
    
    File.write(
      backup_dir.join('06_orders.json'),
      JSON.pretty_generate(orders)
    )
    
    puts "✅ #{orders.count} vendas exportadas (limitado a 100 para teste)"
  end
  
  def restore_company_data(backup_dir)
    puts "\n📥 Restaurando empresa..."
    
    file_path = backup_dir.join('01_company.json')
    return unless File.exist?(file_path)
    
    company_data = JSON.parse(File.read(file_path))
    
    # Verifica se já existe
    existing_company = Company.find_by(name: company_data['name'])
    
    if existing_company
      puts "⚠️  Empresa já existe (ID: #{existing_company.id})"
      @souq_company = existing_company
    else
      @souq_company = Company.create!(
        name: company_data['name'],
        active: company_data['active'],
        description: company_data['description'],
        simplified_frontend: company_data['simplified_frontend']
      )
      puts "✅ Empresa criada (ID: #{@souq_company.id})"
    end
  end
  
  def restore_store_data(backup_dir)
    puts "\n📥 Restaurando loja..."
    
    file_path = backup_dir.join('02_store.json')
    return unless File.exist?(file_path)
    
    store_data = JSON.parse(File.read(file_path))
    
    # Verifica se já existe
    existing_store = Store.find_by(
      company_id: @souq_company.id,
      name: store_data['name']
    )
    
    if existing_store
      puts "⚠️  Loja já existe (ID: #{existing_store.id})"
      @souq_store = existing_store
    else
      @souq_store = Store.create!(
        company_id: @souq_company.id,
        name: store_data['name']
      )
      puts "✅ Loja criada (ID: #{@souq_store.id})"
    end
  end
  
  def restore_category_data(backup_dir)
    puts "\n📥 Restaurando categoria..."
    
    file_path = backup_dir.join('03_category.json')
    return unless File.exist?(file_path)
    
    category_data = JSON.parse(File.read(file_path))
    
    @outros_category = Category.find_or_create_by(
      company_id: @souq_company.id,
      external_id: category_data['external_id']
    ) do |cat|
      cat.name = category_data['name']
    end
    
    puts "✅ Categoria: #{@outros_category.name} (ID: #{@outros_category.id})"
  end
  
  def restore_sellers_data(backup_dir)
    puts "\n📥 Restaurando vendedores..."
    
    file_path = backup_dir.join('04_sellers.json')
    return unless File.exist?(file_path)
    
    sellers_data = JSON.parse(File.read(file_path))
    created_count = 0
    skipped_count = 0
    
    sellers_data.each do |seller_data|
      existing_seller = Seller.find_by(
        company_id: @souq_company.id,
        external_id: seller_data['external_id']
      )
      
      if existing_seller
        skipped_count += 1
      else
        Seller.create!(
          company_id: @souq_company.id,
          store_id: @souq_store.id,
          name: seller_data['name'],
          external_id: seller_data['external_id'],
          email: seller_data['email'],
          whatsapp: seller_data['whatsapp'],
          store_admin: seller_data['store_admin']
        )
        created_count += 1
      end
    end
    
    puts "✅ Vendedores: #{created_count} criados, #{skipped_count} já existiam"
  end
  
  def restore_products_data(backup_dir)
    puts "\n📥 Restaurando produtos..."
    
    file_path = backup_dir.join('05_products.json')
    return unless File.exist?(file_path)
    
    products_data = JSON.parse(File.read(file_path))
    created_count = 0
    skipped_count = 0
    
    products_data.each do |product_data|
      existing_product = Product.find_by(external_id: product_data['external_id'])
      
      if existing_product
        skipped_count += 1
      else
        Product.create!(
          category_id: @outros_category.id,
          external_id: product_data['external_id'],
          name: product_data['name'],
          sku: product_data['sku']
        )
        created_count += 1
      end
    end
    
    puts "✅ Produtos: #{created_count} criados, #{skipped_count} já existiam"
  end
  
  def restore_orders_data(backup_dir)
    puts "\n📥 Restaurando vendas..."
    
    file_path = backup_dir.join('06_orders.json')
    return unless File.exist?(file_path)
    
    orders_data = JSON.parse(File.read(file_path))
    created_orders = 0
    created_items = 0
    skipped_orders = 0
    
    orders_data.each do |order_data|
      # Buscar seller pelo external_id
      seller = Seller.find_by(
        company_id: @souq_company.id,
        external_id: order_data['seller_id']
      )
      
      next unless seller # Pula se vendedor não existe
      
      existing_order = Order.find_by(external_id: order_data['external_id'])
      
      if existing_order
        skipped_orders += 1
        order = existing_order
      else
        order = Order.create!(
          seller_id: seller.id,
          external_id: order_data['external_id'],
          sold_at: order_data['sold_at']
        )
        created_orders += 1
      end
      
      # Criar itens da venda
      order_data['order_items'].each do |item_data|
        product = Product.find_by(external_id: item_data['product_id'])
        next unless product
        
        existing_item = OrderItem.find_by(
          order_id: order.id,
          product_id: product.id
        )
        
        unless existing_item
          OrderItem.create!(
            order_id: order.id,
            product_id: product.id,
            store_id: @souq_store.id,
            quantity: item_data['quantity'],
            unit_price: item_data['unit_price'],
            external_id: item_data['external_id']
          )
          created_items += 1
        end
      end
    end
    
    puts "✅ Vendas: #{created_orders} criadas, #{skipped_orders} já existiam"
    puts "✅ Itens: #{created_items} criados"
  end
end
