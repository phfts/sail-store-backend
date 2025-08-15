require 'csv'

# Configuração do Google Drive
SOUQ_GOOGLE_DRIVE_FOLDER_ID = ENV['SOUQ_GOOGLE_DRIVE_FOLDER_ID'] || 'your_folder_id_here'

namespace :souq do
  desc "Carrega todos os dados SOUQ na ordem correta"
  task load_all: :environment do
    puts "🎯 CARREGAMENTO DE DADOS SOUQ"
    puts "=" * 60
    
    Rake::Task["souq:create_company"].invoke
    Rake::Task["souq:create_store"].invoke
    Rake::Task["souq:create_category"].invoke
    Rake::Task["souq:load_sellers"].invoke
    Rake::Task["souq:load_products"].invoke
    Rake::Task["souq:load_orders"].invoke
    # Rake::Task["souq:load_exchanges"].invoke  # Arquivo não encontrado na pasta
    # Rake::Task["souq:load_returns"].invoke    # Arquivo não encontrado na pasta
    
    puts "\n🎉 CARREGAMENTO CONCLUÍDO COM SUCESSO!"
  end

  desc "Cria a empresa SOUQ"
  task create_company: :environment do
    puts "🏢 Criando empresa SOUQ..."
    
    company_data = {
      name: "SOUQ",
      active: true,
      description: "SOUQ - SP - PÁTIO HIGIENÓPOLIS - Portal Souq - Matriz",
      simplified_frontend: false
    }
    
    # Verifica se a empresa já existe
    existing_company = Company.find_by(name: company_data[:name])
    
    if existing_company
      puts "⚠️  Empresa SOUQ já existe (ID: #{existing_company.id})"
      @souq_company = existing_company
    else
      # Cria a empresa
      @souq_company = Company.create!(company_data)
      puts "✅ Empresa SOUQ criada com sucesso!"
      puts "   ID: #{@souq_company.id}"
      puts "   Nome: #{@souq_company.name}"
      puts "   Slug: #{@souq_company.slug}"
    end
    
    puts "\n📊 Resumo:"
    puts "   Total de empresas: #{Company.count}"
    puts "   Empresa SOUQ ID: #{@souq_company.id}"
    
    # Salva o ID da empresa para uso nas próximas tarefas
    File.write('tmp/souq_company_id.txt', @souq_company.id.to_s)
    puts "\n💾 ID da empresa salvo em tmp/souq_company_id.txt"
  end

  desc "Cria a loja PÁTIO HIGIENÓPOLIS"
  task create_store: :environment do
    puts "🏪 Criando loja PÁTIO HIGIENÓPOLIS..."
    
    # Carrega o ID da empresa
    company_id = File.read('tmp/souq_company_id.txt').strip
    @souq_company = Company.find(company_id)
    
    store_data = {
      company_id: @souq_company.id,
      name: "PÁTIO HIGIENÓPOLIS",
      cnpj: "16945787001508",
      address: "PÁTIO HIGIENÓPOLIS - São Paulo, SP"
    }
    
    # Verifica se a loja já existe
    existing_store = Store.find_by(company_id: @souq_company.id, name: store_data[:name])
    
    if existing_store
      puts "⚠️  Loja PÁTIO HIGIENÓPOLIS já existe (ID: #{existing_store.id})"
      @souq_store = existing_store
    else
      # Cria a loja
      @souq_store = Store.create!(store_data)
      puts "✅ Loja PÁTIO HIGIENÓPOLIS criada com sucesso!"
      puts "   ID: #{@souq_store.id}"
      puts "   Nome: #{@souq_store.name}"
      puts "   Slug: #{@souq_store.slug}"
      puts "   Empresa: #{@souq_store.company.name}"
    end
    
    puts "\n📊 Resumo:"
    puts "   Total de lojas: #{Store.count}"
    puts "   Loja PÁTIO HIGIENÓPOLIS ID: #{@souq_store.id}"
    puts "   Turnos criados: #{@souq_store.shifts.count}"
    
    # Salva o ID da loja para uso nas próximas tarefas
    File.write('tmp/souq_store_id.txt', @souq_store.id.to_s)
    puts "\n💾 ID da loja salvo em tmp/souq_store_id.txt"
  end

  desc "Cria a categoria 'Outros'"
  task create_category: :environment do
    puts "📂 Criando categoria 'Outros'..."
    
    # Carrega o ID da empresa
    company_id = File.read('tmp/souq_company_id.txt').strip
    @souq_company = Company.find(company_id)
    
    # Cria categoria "Outros" se não existir
    @outros_category = Category.find_or_create_by(
      company_id: @souq_company.id,
      external_id: 'outros'
    ) do |cat|
      cat.name = 'Outros'
    end
    
    puts "✅ Categoria: #{@outros_category.name} (ID: #{@outros_category.id})"
    
    # Salva o ID da categoria para uso nas próximas tarefas
    File.write('tmp/souq_category_id.txt', @outros_category.id.to_s)
    puts "\n💾 ID da categoria salvo em tmp/souq_category_id.txt"
  end

  desc "Carrega vendedores do arquivo CSV"
  task load_sellers: :environment do
    puts "👥 Carregando vendedores..."
    
    # Carrega os IDs
    company_id = File.read('tmp/souq_company_id.txt').strip
    store_id = File.read('tmp/souq_store_id.txt').strip
    @souq_company = Company.find(company_id)
    @souq_store = Store.find(store_id)
    
    # Inicializa o serviço do Google Drive
    drive_service = GoogleDriveService.new
    
    # Nome do arquivo CSV
    csv_filename = "sellers"
    
    # Baixa o arquivo do Google Drive
    puts "📥 Baixando arquivo do Google Drive: #{csv_filename}"
    csv_file = drive_service.download_csv_file(SOUQ_GOOGLE_DRIVE_FOLDER_ID, csv_filename)
    
    unless csv_file
      puts "❌ Arquivo CSV não encontrado no Google Drive: #{csv_filename}"
      exit 1
    end
    
    puts "📁 Lendo arquivo: #{csv_filename}"
    
    created_count = 0
    skipped_count = 0
    error_count = 0
    
    CSV.foreach(csv_file, headers: true, encoding: 'UTF-8') do |row|
      # Pula vendedores inativos ou vazios
      next if row['ativo'] == 'N' || row['nome_vendedor'].blank?
      
      # Pula vendedores especiais (SOUQ, IDA, etc.)
      nome = row['nome_vendedor'].strip
      next if nome.match?(/^(SOUQ|IDA|OMNI|Vendedor OMNI|SOUQ-|IDA-)/i)
      
      # Dados do vendedor
      seller_data = {
        company_id: @souq_company.id,
        store_id: @souq_store.id,
        name: nome,
        external_id: row['cod_vendedor'],
        email: row['mail_vendedor'].presence,
        whatsapp: row['fone_vendedor'].presence,
        store_admin: false
      }
      
      # Verifica se o vendedor já existe
      existing_seller = Seller.find_by(
        company_id: @souq_company.id,
        external_id: seller_data[:external_id]
      )
      
      if existing_seller
        skipped_count += 1
        puts "⏭️  Vendedor já existe: #{nome} (ID: #{existing_seller.id})"
      else
        begin
          seller = Seller.create!(seller_data)
          created_count += 1
          puts "✅ Vendedor criado: #{nome} (ID: #{seller.id})"
        rescue => e
          error_count += 1
          puts "❌ Erro ao criar vendedor #{nome}: #{e.message}"
        end
      end
    end
    
    puts "\n📊 Resumo final:"
    puts "   Vendedores criados: #{created_count}"
    puts "   Vendedores ignorados: #{skipped_count}"
    puts "   Vendedores com erro: #{error_count}"
    puts "   Total de vendedores na empresa: #{Seller.where(company_id: @souq_company.id).count}"
    puts "   Total de vendedores na loja: #{Seller.where(store_id: @souq_store.id).count}"
    
    # Limpa o arquivo temporário
    File.unlink(csv_file) if csv_file && File.exist?(csv_file)
    puts "🗑️  Arquivo temporário removido"
  end

  desc "Carrega produtos do arquivo CSV"
  task load_products: :environment do
    puts "📦 Carregando produtos..."
    
    # Carrega os IDs
    company_id = File.read('tmp/souq_company_id.txt').strip
    category_id = File.read('tmp/souq_category_id.txt').strip
    @souq_company = Company.find(company_id)
    @outros_category = Category.find(category_id)
    
    # Inicializa o serviço do Google Drive
    drive_service = GoogleDriveService.new
    
    # Nome do arquivo CSV de produtos
    csv_filename = "products"
    
    # Baixa o arquivo do Google Drive
    puts "📥 Baixando arquivo de produtos do Google Drive: #{csv_filename}"
    csv_file = drive_service.download_csv_file(SOUQ_GOOGLE_DRIVE_FOLDER_ID, csv_filename)
    
    unless csv_file
      puts "❌ Nenhum arquivo CSV de produtos encontrado no Google Drive"
      exit 1
    end
    
    puts "📁 Lendo arquivo de produtos..."
    
    created_count = 0
    skipped_count = 0
    error_count = 0
    
    CSV.foreach(csv_file, headers: true, encoding: 'UTF-8') do |row|
      # Pula produtos desativados ou vazios
      next if row['desativado'] == 'S' || row['nome'].blank? || row['cod_produto'].blank?
      
      # Dados do produto
      product_data = {
        category_id: @outros_category.id,
        external_id: row['cod_produto'],
        name: row['nome'].strip,
        sku: row['cod_barra'].presence || row['cod_produto']
      }
      
      # Verifica se o produto já existe
      existing_product = Product.find_by(external_id: product_data[:external_id])
      
      if existing_product
        skipped_count += 1
      else
        begin
          product = Product.create!(product_data)
          created_count += 1
        rescue => e
          error_count += 1
          puts "❌ Erro ao criar produto #{product_data[:name]}: #{e.message}"
        end
      end
    end
    
    puts "\n📊 Resumo final:"
    puts "   Produtos criados: #{created_count}"
    puts "   Produtos ignorados: #{skipped_count}"
    puts "   Produtos com erro: #{error_count}"
    puts "   Total de produtos na categoria: #{@outros_category.products.count}"
    puts "   Total de produtos no sistema: #{Product.count}"
    
    # Limpa o arquivo temporário
    File.unlink(csv_file) if csv_file && File.exist?(csv_file)
    puts "🗑️  Arquivo temporário removido"
  end

  desc "Carrega vendas do arquivo CSV"
  task load_orders: :environment do
    puts "🛒 Carregando vendas..."
    
    # Carrega os IDs
    company_id = File.read('tmp/souq_company_id.txt').strip
    store_id = File.read('tmp/souq_store_id.txt').strip
    @souq_company = Company.find(company_id)
    @souq_store = Store.find(store_id)
    
    # Inicializa o serviço do Google Drive
    drive_service = GoogleDriveService.new
    
    # Nome do arquivo CSV de vendas
    csv_filename = "orders"
    
    # Baixa o arquivo do Google Drive
    puts "📥 Baixando arquivo de vendas do Google Drive: #{csv_filename}"
    csv_file = drive_service.download_csv_file(SOUQ_GOOGLE_DRIVE_FOLDER_ID, csv_filename)
    
    unless csv_file
      puts "❌ Nenhum arquivo CSV de vendas encontrado no Google Drive"
      exit 1
    end
    
    puts "📁 Lendo arquivo de vendas..."
    
    created_count = 0
    skipped_count = 0
    error_count = 0
    
    CSV.foreach(csv_file, headers: true, encoding: 'UTF-8') do |row|
      # Pula vendas canceladas ou excluídas
      next if row['cancelado'] == 'S' || row['excluido'] == 'S'
      
      # Pula se não tem vendedor ou produto
      next if row['cod_vendedor'].blank? || row['cod_produto'].blank?
      
      # Busca o vendedor
      seller = Seller.find_by(
        company_id: @souq_company.id,
        external_id: row['cod_vendedor']
      )
      
      next unless seller
      
      # Busca o produto
      product = Product.find_by(external_id: row['cod_produto'])
      
      next unless product
      
      # Dados da venda
      sold_at = begin
        Date.parse(row['data_documento'])
      rescue
        Date.current
      end
      
      order_data = {
        seller_id: seller.id,
        external_id: row['documento'],
        sold_at: sold_at
      }
      
      # Busca ou cria a venda
      order = Order.find_by(external_id: order_data[:external_id])
      
      if order.nil?
        begin
          # Cria a venda
          order = Order.create!(order_data)
          created_count += 1
        rescue => e
          error_count += 1
          puts "❌ Erro ao criar venda #{order_data[:external_id]}: #{e.message}"
          next
        end
      else
        skipped_count += 1
      end
      
      # Sempre cria o item da venda (mesmo se o pedido já existia)
      begin
        quantity = row['quantidade'].to_f
        unit_price = row['preco_unitario'].to_f
        
        # Verifica se este item específico já existe
        existing_item = OrderItem.find_by(
          order_id: order.id,
          product_id: product.id
        )
        
        unless existing_item
          OrderItem.create!(
            order_id: order.id,
            product_id: product.id,
            store_id: @souq_store.id,
            quantity: quantity,
            unit_price: unit_price,
            external_id: row['transacao']
          )
        end
      rescue => e
        error_count += 1
        puts "❌ Erro ao criar item da venda #{order.external_id}: #{e.message}"
      end
    end
    
    puts "\n📊 Resumo final:"
    puts "   Vendas criadas: #{created_count}"
    puts "   Vendas ignoradas: #{skipped_count}"
    puts "   Vendas com erro: #{error_count}"
    puts "   Total de vendas no sistema: #{Order.count}"
    puts "   Total de itens de venda: #{OrderItem.count}"
    
    # Limpa o arquivo temporário
    File.unlink(csv_file) if csv_file && File.exist?(csv_file)
    puts "🗑️  Arquivo temporário removido"
  end

  desc "Limpa todos os dados SOUQ"
  task clean: :environment do
    puts "🧹 Limpando dados SOUQ..."
    
    # Busca a empresa SOUQ
    company = Company.find_by(name: 'SOUQ')
    
    if company
      puts "🗑️  Removendo empresa SOUQ e todos os dados relacionados..."
      
      # Remove a empresa (isso remove tudo relacionado devido às dependências)
      company.destroy
      
      puts "✅ Dados SOUQ removidos com sucesso!"
    else
      puts "ℹ️  Empresa SOUQ não encontrada"
    end
    
    # Remove arquivos temporários
    File.delete('tmp/souq_company_id.txt') if File.exist?('tmp/souq_company_id.txt')
    File.delete('tmp/souq_store_id.txt') if File.exist?('tmp/souq_store_id.txt')
    File.delete('tmp/souq_category_id.txt') if File.exist?('tmp/souq_category_id.txt')
    
    puts "🗂️  Arquivos temporários removidos"
  end

  desc "Carrega trocas do arquivo CSV"
  task load_exchanges: :environment do
    puts "🔄 Carregando trocas..."
    
    # Carrega os IDs
    company_id = File.read('tmp/souq_company_id.txt').strip
    @souq_company = Company.find(company_id)
    
    # Inicializa o serviço do Google Drive
    drive_service = GoogleDriveService.new
    
    # Padrão para buscar o arquivo mais recente de trocas
    exchanges_pattern = /LinxMovimentoTrocas_store=16945787001508_beginDate=\d{4}-\d{2}-\d{2}_endDate=\d{4}-\d{2}-\d{2}\.csv/
    
    # Baixa o arquivo mais recente do Google Drive
    puts "📥 Buscando arquivo mais recente de trocas no Google Drive..."
    csv_file = drive_service.download_latest_csv_file(SOUQ_GOOGLE_DRIVE_FOLDER_ID, exchanges_pattern)
    
    unless csv_file
      puts "❌ Nenhum arquivo CSV de trocas encontrado no Google Drive"
      exit 1
    end
    
    puts "📁 Lendo arquivo de trocas..."
    
    created_count = 0
    skipped_count = 0
    error_count = 0
    
    CSV.foreach(csv_file, headers: true, encoding: 'UTF-8') do |row|
      # Pula registros excluídos ou vazios
      next if row['excluido'] == 'True' || row['identificador'].blank?
      
      # Converte timestamp para datetime
      processed_at = begin
        Time.at(row['timestamp'].to_i)
      rescue
        Time.current
      end
      
      # Busca vendedor se houver código
      seller = nil
      if row['vale_cod_cliente'].present?
        # Tenta encontrar o vendedor pelo código do cliente (pode não existir)
        seller = Seller.find_by(
          company_id: @souq_company.id,
          external_id: row['vale_cod_cliente']
        )
      end
      
      # Busca orders relacionadas se houver documentos
      original_order = nil
      new_order = nil
      
      if row['doc_origem'].present? && row['doc_origem'] != '0'
        original_order = Order.find_by(external_id: row['doc_origem'])
      end
      
      if row['doc_venda'].present? && row['doc_venda'] != '0'
        new_order = Order.find_by(external_id: row['doc_venda'])
      end
      
      # Determina se é crédito ou débito baseado no valor original
      is_credit = row['valor_original'].present? && !row['valor_original'].include?('-')
      
      # Dados da troca
      exchange_data = {
        external_id: row['identificador'].presence || "#{row['num_vale']}_#{row['timestamp']}",
        voucher_number: row['num_vale'],
        voucher_value: row['valor_vale'].gsub(',', '.').to_f,
        exchange_type: row['motivo'],
        original_document: row['doc_origem'],
        new_document: row['doc_venda'],
        customer_code: row['cod_cliente'],
        is_credit: is_credit,
        processed_at: processed_at,
        seller: seller,
        original_order: original_order,
        new_order: new_order
      }
      
      # Verifica se a troca já existe
      existing_exchange = Exchange.find_by(external_id: exchange_data[:external_id])
      
      if existing_exchange
        skipped_count += 1
      else
        begin
          exchange = Exchange.create!(exchange_data)
          created_count += 1
        rescue => e
          error_count += 1
          puts "❌ Erro ao criar troca #{exchange_data[:external_id]}: #{e.message}"
        end
      end
    end
    
    puts "\n📊 Resumo final:"
    puts "   Trocas criadas: #{created_count}"
    puts "   Trocas ignoradas: #{skipped_count}"
    puts "   Trocas com erro: #{error_count}"
    puts "   Total de trocas no sistema: #{Exchange.count}"
    
    # Limpa o arquivo temporário
    File.unlink(csv_file) if csv_file && File.exist?(csv_file)
    puts "🗑️  Arquivo temporário removido"
  end

  desc "Carrega devoluções do arquivo CSV"
  task load_returns: :environment do
    puts "📦 Carregando devoluções..."
    
    # Inicializa o serviço do Google Drive
    drive_service = GoogleDriveService.new
    
    # Nome do arquivo CSV de devoluções
    returns_filename = "LinxMovimentoDevolucoesItens_store=16945787001508_historical.csv"
    
    # Baixa o arquivo do Google Drive
    puts "📥 Baixando arquivo de devoluções do Google Drive: #{returns_filename}"
    csv_file = drive_service.download_csv_file(SOUQ_GOOGLE_DRIVE_FOLDER_ID, returns_filename)
    
    unless csv_file
      puts "❌ Arquivo CSV de devoluções não encontrado no Google Drive: #{returns_filename}"
      exit 1
    end
    
    puts "📁 Lendo arquivo de devoluções..."
    
    created_count = 0
    skipped_count = 0
    error_count = 0
    
    CSV.foreach(csv_file, headers: true, encoding: 'UTF-8') do |row|
      # Pula registros vazios
      next if row['identificador_devolucao'].blank? || row['codigoproduto'].blank?
      
      # Converte timestamp para datetime
      processed_at = begin
        Time.at(row['timestamp'].to_i)
      rescue
        Time.current
      end
      
      # Busca a venda original
      original_order = Order.find_by(external_id: row['identificador_venda'])
      
      # Busca o produto
      product = Product.find_by(external_id: row['codigoproduto'])
      
      # Dados da devolução
      return_data = {
        external_id: row['identificador_devolucao'],
        original_sale_id: row['identificador_venda'],
        product_external_id: row['codigoproduto'],
        original_transaction: row['transacao_origem'],
        return_transaction: row['transacao_devolucao'],
        quantity_returned: row['qtde_devolvida'].to_f,
        processed_at: processed_at,
        original_order: original_order,
        product: product
      }
      
      # Verifica se a devolução já existe
      existing_return = Return.find_by(external_id: return_data[:external_id])
      
      if existing_return
        skipped_count += 1
      else
        begin
          return_record = Return.create!(return_data)
          created_count += 1
        rescue => e
          error_count += 1
          puts "❌ Erro ao criar devolução #{return_data[:external_id]}: #{e.message}"
        end
      end
    end
    
    puts "\n📊 Resumo final:"
    puts "   Devoluções criadas: #{created_count}"
    puts "   Devoluções ignoradas: #{skipped_count}"
    puts "   Devoluções com erro: #{error_count}"
    puts "   Total de devoluções no sistema: #{Return.count}"
    
    # Limpa o arquivo temporário
    File.unlink(csv_file) if csv_file && File.exist?(csv_file)
    puts "🗑️  Arquivo temporário removido"
  end
end
