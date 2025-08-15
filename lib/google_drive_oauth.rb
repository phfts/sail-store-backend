require 'googleauth'
require 'googleauth/stores/file_token_store'
require 'google_drive'
require 'webrick'
require 'uri'

class GoogleDriveOauth
  SCOPE = ['https://www.googleapis.com/auth/drive.readonly'].freeze
  REDIRECT_URI = 'http://localhost:8080/oauth2callback'
  
  def self.authenticate(config_file)
    config = JSON.parse(File.read(config_file))
    client_id = config['client_id']
    client_secret = config['client_secret']
    
    # Cria o cliente OAuth2
    authorizer = Google::Auth::UserAuthorizer.new(
      Google::Auth::ClientId.new(client_id, client_secret),
      SCOPE,
      Google::Auth::Stores::FileTokenStore.new(file: Rails.root.join('tmp', 'google_drive_tokens.yaml'))
    )
    
    # Tenta carregar credenciais existentes
    credentials = authorizer.get_credentials('default')
    
    if credentials.nil?
      # Precisa fazer autenticação
      puts "🌐 Abrindo navegador para autenticação..."
      
      # Gera URL de autorização
      auth_url = authorizer.get_authorization_url(base_url: REDIRECT_URI)
      
      # Abre o navegador
      system("xdg-open '#{auth_url}' || open '#{auth_url}' || start '#{auth_url}'")
      
      # Inicia servidor local para receber o callback
      code = start_callback_server
      
      if code
        # Troca o código por credenciais
        credentials = authorizer.get_and_store_credentials_from_code(
          user_id: 'default',
          code: code,
          base_url: REDIRECT_URI
        )
        puts "✅ Autenticação realizada com sucesso!"
      else
        raise "Falha na autenticação"
      end
    else
      puts "✅ Usando credenciais salvas"
    end
    
    # Cria sessão do Google Drive
    session = GoogleDrive::Session.from_credentials(credentials)
    session
  end
  
  private
  
  def self.start_callback_server
    code = nil
    
    server = WEBrick::HTTPServer.new(
      Port: 8080,
      Logger: WEBrick::Log.new('/dev/null'),
      AccessLog: []
    )
    
    server.mount_proc '/oauth2callback' do |req, res|
      if req.query['code']
        code = req.query['code']
        res.body = '<h1>✅ Autenticação realizada com sucesso!</h1><p>Você pode fechar esta janela.</p>'
        res.content_type = 'text/html'
      else
        res.body = '<h1>❌ Erro na autenticação</h1>'
        res.content_type = 'text/html'
      end
      
      # Para o servidor após receber a resposta
      Thread.new { sleep 1; server.shutdown }
    end
    
    puts "🔗 Aguardando callback em http://localhost:8080/oauth2callback"
    
    begin
      server.start
    rescue => e
      puts "Erro no servidor: #{e.message}"
    end
    
    code
  end
end
