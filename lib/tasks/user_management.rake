namespace :user do
  desc "Alterar senha de um usuário"
  task change_password: :environment do
    puts "=== ALTERAÇÃO DE SENHA DE USUÁRIO ==="
    puts
    
    # Solicitar email do usuário
    print "Digite o email do usuário: "
    email = STDIN.gets.chomp
    
    # Validar se o email não está vazio
    if email.blank?
      puts "❌ Email não pode estar vazio!"
      exit 1
    end
    
    # Buscar o usuário
    user = User.find_by(email: email)
    
    unless user
      puts "❌ Usuário não encontrado com o email: #{email}"
      exit 1
    end
    
    puts "✅ Usuário encontrado: #{user.email} (#{user.admin? ? 'Admin' : 'Usuário normal'})"
    puts
    
    # Solicitar nova senha
    print "Digite a nova senha: "
    new_password = STDIN.gets.chomp
    
    # Validar se a senha não está vazia
    if new_password.blank?
      puts "❌ Senha não pode estar vazia!"
      exit 1
    end
    
    # Validar tamanho mínimo da senha
    if new_password.length < 6
      puts "❌ Senha deve ter pelo menos 6 caracteres!"
      exit 1
    end
    
    # Confirmar a senha
    print "Confirme a nova senha: "
    password_confirmation = STDIN.gets.chomp
    
    unless new_password == password_confirmation
      puts "❌ Senhas não coincidem!"
      exit 1
    end
    
    # Atualizar a senha
    begin
      user.update!(password: new_password)
      puts
      puts "✅ Senha alterada com sucesso para o usuário: #{user.email}"
      puts "🔑 Nova senha definida!"
    rescue => e
      puts "❌ Erro ao alterar senha: #{e.message}"
      exit 1
    end
  end

  desc "Listar todos os usuários"
  task list: :environment do
    puts "=== LISTA DE USUÁRIOS ==="
    puts
    
    users = User.all.order(:email)
    
    if users.empty?
      puts "Nenhum usuário encontrado."
      return
    end
    
    puts "ID".ljust(5) + "Email".ljust(30) + "Admin".ljust(8) + "Criado em"
    puts "-" * 65
    
    users.each do |user|
      admin_status = user.admin? ? "Sim" : "Não"
      created_at = user.created_at.strftime("%d/%m/%Y %H:%M")
      
      puts "#{user.id.to_s.ljust(5)}#{user.email.ljust(30)}#{admin_status.ljust(8)}#{created_at}"
    end
    
    puts
    puts "Total: #{users.count} usuário(s)"
  end

  desc "Criar novo usuário admin"
  task create_admin: :environment do
    puts "=== CRIAR NOVO USUÁRIO ADMIN ==="
    puts
    
    # Solicitar email
    print "Digite o email do novo admin: "
    email = STDIN.gets.chomp
    
    # Validar email
    if email.blank?
      puts "❌ Email não pode estar vazio!"
      exit 1
    end
    
    # Verificar se email já existe
    if User.exists?(email: email)
      puts "❌ Já existe um usuário com este email!"
      exit 1
    end
    
    # Solicitar senha
    print "Digite a senha: "
    password = STDIN.gets.chomp
    
    # Validar senha
    if password.blank?
      puts "❌ Senha não pode estar vazia!"
      exit 1
    end
    
    if password.length < 6
      puts "❌ Senha deve ter pelo menos 6 caracteres!"
      exit 1
    end
    
    # Confirmar senha
    print "Confirme a senha: "
    password_confirmation = STDIN.gets.chomp
    
    unless password == password_confirmation
      puts "❌ Senhas não coincidem!"
      exit 1
    end
    
    # Criar usuário
    begin
      user = User.create!(
        email: email,
        password: password,
        admin: true
      )
      
      puts
      puts "✅ Usuário admin criado com sucesso!"
      puts "📧 Email: #{user.email}"
      puts "🔑 Senha definida!"
      puts "👑 Status: Admin"
    rescue => e
      puts "❌ Erro ao criar usuário: #{e.message}"
      exit 1
    end
  end

  desc "Promover usuário para admin"
  task promote_to_admin: :environment do
    puts "=== PROMOVER USUÁRIO PARA ADMIN ==="
    puts
    
    # Solicitar email
    print "Digite o email do usuário: "
    email = STDIN.gets.chomp
    
    if email.blank?
      puts "❌ Email não pode estar vazio!"
      exit 1
    end
    
    # Buscar usuário
    user = User.find_by(email: email)
    
    unless user
      puts "❌ Usuário não encontrado com o email: #{email}"
      exit 1
    end
    
    if user.admin?
      puts "⚠️ Usuário já é admin: #{user.email}"
      return
    end
    
    # Confirmar promoção
    print "Confirma a promoção de #{user.email} para admin? (s/N): "
    confirmation = STDIN.gets.chomp.downcase
    
    unless ['s', 'sim', 'y', 'yes'].include?(confirmation)
      puts "❌ Operação cancelada."
      return
    end
    
    # Promover usuário
    begin
      user.update!(admin: true)
      puts "✅ Usuário promovido para admin: #{user.email}"
    rescue => e
      puts "❌ Erro ao promover usuário: #{e.message}"
      exit 1
    end
  end

  desc "Remover privilégios de admin"
  task demote_from_admin: :environment do
    puts "=== REMOVER PRIVILÉGIOS DE ADMIN ==="
    puts
    
    # Solicitar email
    print "Digite o email do admin: "
    email = STDIN.gets.chomp
    
    if email.blank?
      puts "❌ Email não pode estar vazio!"
      exit 1
    end
    
    # Buscar usuário
    user = User.find_by(email: email)
    
    unless user
      puts "❌ Usuário não encontrado com o email: #{email}"
      exit 1
    end
    
    unless user.admin?
      puts "⚠️ Usuário não é admin: #{user.email}"
      return
    end
    
    # Verificar se é o último admin
    admin_count = User.where(admin: true).count
    if admin_count <= 1
      puts "❌ Não é possível remover o último admin do sistema!"
      exit 1
    end
    
    # Confirmar remoção
    print "Confirma a remoção dos privilégios de admin de #{user.email}? (s/N): "
    confirmation = STDIN.gets.chomp.downcase
    
    unless ['s', 'sim', 'y', 'yes'].include?(confirmation)
      puts "❌ Operação cancelada."
      return
    end
    
    # Remover privilégios
    begin
      user.update!(admin: false)
      puts "✅ Privilégios de admin removidos: #{user.email}"
    rescue => e
      puts "❌ Erro ao remover privilégios: #{e.message}"
      exit 1
    end
  end
end
