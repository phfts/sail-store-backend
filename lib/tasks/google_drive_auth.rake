require 'google_drive'

namespace :google_drive do
  desc "Configura autenticação do Google Drive via OAuth2"
  task setup_auth: :environment do
    puts "🔐 CONFIGURAÇÃO DE AUTENTICAÇÃO GOOGLE DRIVE"
    puts "=" * 60
    
    puts "\n📋 PASSO 1: Criar credenciais OAuth2"
    puts "1. Acesse: https://console.cloud.google.com/"
    puts "2. Selecione seu projeto ou crie um novo"
    puts "3. Vá para 'APIs & Services' > 'Credentials'"
    puts "4. Clique em 'Create Credentials' > 'OAuth 2.0 Client IDs'"
    puts "5. Tipo: 'Desktop application'"
    puts "6. Nome: 'SOUQ Data Importer'"
    puts "7. Baixe o arquivo JSON"
    puts "\n📋 PASSO 2: Habilitar APIs"
    puts "1. Vá para 'APIs & Services' > 'Library'"
    puts "2. Procure e habilite: 'Google Drive API'"
    puts "\n📋 PASSO 3: Configurar credenciais"
    
    config_file = Rails.root.join('config', 'google_drive_config.json')
    
    if File.exist?(config_file)
      config = JSON.parse(File.read(config_file))
      if config['client_id'] == 'YOUR_CLIENT_ID'
        puts "\n⚠️  Arquivo de configuração encontrado mas não configurado."
        puts "Edite o arquivo: #{config_file}"
        puts "Substitua YOUR_CLIENT_ID e YOUR_CLIENT_SECRET pelas suas credenciais."
        return
      end
    else
      puts "\n❌ Arquivo de configuração não encontrado: #{config_file}"
      return
    end
    
    puts "\n🚀 Iniciando autenticação..."
    puts "Seu navegador será aberto para fazer login no Google."
    puts "Autorize o acesso ao Google Drive."
    
    begin
      # Usa autenticação com servidor local temporário
      session = GoogleDrive::Session.from_config(config_file.to_s)
      puts "\n✅ Autenticação realizada com sucesso!"
      
      # Testa o acesso à pasta
      folder_id = ENV['SOUQ_GOOGLE_DRIVE_FOLDER_ID']
      if folder_id
        puts "\n🔍 Testando acesso à pasta SOUQ..."
        folder = session.folder_by_id(folder_id)
        puts "✅ Pasta acessada: #{folder.title}"
        puts "📁 Arquivos encontrados: #{folder.files.count}"
        
        puts "\n📋 Lista de arquivos:"
        folder.files.each do |file|
          puts "  - #{file.title}"
        end
      else
        puts "\n⚠️  SOUQ_GOOGLE_DRIVE_FOLDER_ID não configurado no .env"
      end
      
    rescue => e
      puts "\n❌ Erro na autenticação: #{e.message}"
      puts "\nVerifique se:"
      puts "1. As credenciais estão corretas no arquivo de configuração"
      puts "2. A API do Google Drive está habilitada"
      puts "3. Você tem acesso à pasta do Google Drive"
    end
  end
  
  desc "Testa conexão com Google Drive"
  task test_connection: :environment do
    puts "🧪 TESTANDO CONEXÃO GOOGLE DRIVE"
    puts "=" * 40
    
    begin
      service = GoogleDriveService.new
      folder_id = ENV['SOUQ_GOOGLE_DRIVE_FOLDER_ID']
      
      if folder_id.blank?
        puts "❌ SOUQ_GOOGLE_DRIVE_FOLDER_ID não configurado"
        next
      end
      
      puts "📁 Listando arquivos na pasta..."
      files = service.list_files_in_folder(folder_id)
      
      puts "✅ Conexão bem-sucedida!"
      puts "📊 Total de arquivos: #{files.count}"
      
      puts "\n📋 Arquivos encontrados:"
      files.each do |filename|
        puts "  - #{filename}"
      end
      
    rescue => e
      puts "❌ Erro: #{e.message}"
      puts "\nExecute primeiro: rails google_drive:setup_auth"
    end
  end
end
