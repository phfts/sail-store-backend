require 'google_drive'
require 'tempfile'
require_relative '../../lib/google_drive_oauth'

class GoogleDriveService
  def initialize
    # Usa autenticação OAuth2 via navegador para desenvolvimento
    config_file = Rails.root.join('config', 'google_drive_config.json')
    @session = GoogleDriveOAuth.authenticate(config_file)
  end

  # Busca arquivo por nome em uma pasta específica
  def find_file_in_folder(folder_id, file_name)
    folder = @session.folder_by_id(folder_id)
    item = folder.files.find { |file| file.title == file_name }
    
    # Se for uma pasta, procura dentro dela por arquivos CSV
    if item && item.mime_type == 'application/vnd.google-apps.folder'
      puts "📁 '#{file_name}' é uma pasta, procurando arquivos CSV dentro..."
      subfolder = @session.folder_by_id(item.id)
      csv_files = subfolder.files.select { |f| 
        f.title.downcase.include?('.csv') || 
        f.mime_type == 'application/vnd.google-apps.spreadsheet' ||
        f.mime_type == 'text/csv'
      }
      
      puts "📋 Arquivos encontrados na pasta '#{file_name}':"
      csv_files.each { |f| puts "  - #{f.title} (#{f.mime_type})" }
      
      # Busca arquivos específicos da loja SOUQ (store=16945787001508)
      case file_name
      when 'sellers'
        souq_file = csv_files.find { |f| f.title.include?('store=16945787001508') }
        return souq_file if souq_file
      when 'products'
        # Busca o arquivo mais recente de produtos da SOUQ
        souq_files = csv_files.select { |f| f.title.include?('store=16945787001508') }
        return souq_files.max_by { |f| f.title } if souq_files.any?
      when 'orders'
        # Busca o arquivo mais recente de pedidos da SOUQ
        souq_files = csv_files.select { |f| f.title.include?('store=16945787001508') }
        return souq_files.max_by { |f| f.title } if souq_files.any?
      end
      
      # Retorna o primeiro arquivo encontrado
      return csv_files.first
    end
    
    item
  end

  # Baixa arquivo CSV e retorna o caminho temporário
  def download_csv_file(folder_id, file_name)
    file = find_file_in_folder(folder_id, file_name)
    
    unless file
      Rails.logger.error "Arquivo não encontrado: #{file_name} na pasta #{folder_id}"
      return nil
    end

    # Cria arquivo temporário
    temp_file = Tempfile.new([File.basename(file_name), '.csv'])
    
    begin
      puts "📊 Tipo do arquivo: #{file.mime_type}"
      
      # Se for um Google Sheets, baixa como CSV
      if file.mime_type == 'application/vnd.google-apps.spreadsheet'
        puts "📊 Detectado Google Sheets, baixando como CSV..."
        # Converte para worksheet e exporta como CSV
        worksheet = file.worksheets[0]  # Primeira aba
        csv_content = worksheet.export_as_string('csv')
        File.write(temp_file.path, csv_content)
      else
        # Baixa o conteúdo do arquivo normalmente
        puts "📄 Baixando arquivo regular..."
        File.open(temp_file.path, 'wb') do |f|
          file.download_to_io(f)
        end
      end
      temp_file.path
    rescue => e
      Rails.logger.error "Erro ao baixar arquivo #{file_name}: #{e.message}"
      puts "❌ Erro detalhado: #{e.message}"
      temp_file.close
      temp_file.unlink
      nil
    end
  end

  # Lista arquivos em uma pasta
  def list_files_in_folder(folder_id)
    folder = @session.folder_by_id(folder_id)
    folder.files.map(&:title)
  end

  # Busca o arquivo CSV mais recente baseado no padrão de nome
  def find_latest_csv_file(folder_id, pattern)
    folder = @session.folder_by_id(folder_id)
    matching_files = folder.files.select { |file| file.title.match?(pattern) }
    
    # Ordena por data de modificação (mais recente primeiro)
    latest_file = matching_files.max_by(&:updated_time)
    latest_file&.title
  end

  # Baixa o arquivo CSV mais recente que corresponde ao padrão
  def download_latest_csv_file(folder_id, pattern)
    latest_file_name = find_latest_csv_file(folder_id, pattern)
    return nil unless latest_file_name

    Rails.logger.info "Baixando arquivo mais recente: #{latest_file_name}"
    download_csv_file(folder_id, latest_file_name)
  end
end
