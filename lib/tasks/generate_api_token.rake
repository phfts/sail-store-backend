namespace :api do
  desc "Generate a super admin API token with full permissions"
  task generate_super_token: :environment do
    # Criar um usuário super admin se não existir
    super_admin = User.find_or_create_by(email: 'api@superadmin.com') do |user|
      user.password = 'superadmin123!'
      user.password_confirmation = 'superadmin123!'
      user.admin = true
    end

    # Gerar token JWT
    payload = {
      user_id: super_admin.id,
      email: super_admin.email,
      admin: true,
      exp: 1.year.from_now.to_i  # Token válido por 1 ano
    }
    
    secret_key = ENV['JWT_SECRET_KEY'] || 'default-secret-key-change-in-production'
    token = JWT.encode(payload, secret_key, 'HS256')
    
    puts "=" * 60
    puts "SUPER ADMIN API TOKEN GERADO"
    puts "=" * 60
    puts "Email: #{super_admin.email}"
    puts "Senha: superadmin123!"
    puts "Admin: #{super_admin.admin?}"
    puts "Token (Bearer): #{token}"
    puts "=" * 60
    puts "Este token tem permissões completas para todas as operações da API"
    puts "Use no header: Authorization: Bearer #{token}"
    puts "=" * 60
  end

  desc "Generate a regular API token for testing"
  task generate_test_token: :environment do
    # Criar um usuário de teste se não existir
    test_user = User.find_or_create_by(email: 'test@api.com') do |user|
      user.password = 'test123!'
      user.password_confirmation = 'test123!'
      user.admin = false
    end

    # Gerar token JWT
    payload = {
      user_id: test_user.id,
      email: test_user.email,
      admin: false,
      exp: 30.days.from_now.to_i  # Token válido por 30 dias
    }
    
    secret_key = ENV['JWT_SECRET_KEY'] || 'default-secret-key-change-in-production'
    token = JWT.encode(payload, secret_key, 'HS256')
    
    puts "=" * 60
    puts "TEST API TOKEN GERADO"
    puts "=" * 60
    puts "Email: #{test_user.email}"
    puts "Senha: test123!"
    puts "Admin: #{test_user.admin?}"
    puts "Token (Bearer): #{token}"
    puts "=" * 60
    puts "Este token tem permissões de usuário regular"
    puts "Use no header: Authorization: Bearer #{token}"
    puts "=" * 60
  end

  desc "List all API tokens and their permissions"
  task list_tokens: :environment do
    puts "=" * 60
    puts "USUÁRIOS E TOKENS DISPONÍVEIS"
    puts "=" * 60
    
    User.all.each do |user|
      payload = {
        user_id: user.id,
        email: user.email,
        admin: user.admin?,
        exp: 24.hours.from_now.to_i
      }
      
      secret_key = ENV['JWT_SECRET_KEY'] || 'default-secret-key-change-in-production'
      token = JWT.encode(payload, secret_key, 'HS256')
      
      puts "Email: #{user.email}"
      puts "Admin: #{user.admin?}"
      puts "Token: #{token}"
      puts "-" * 40
    end
  end
end 