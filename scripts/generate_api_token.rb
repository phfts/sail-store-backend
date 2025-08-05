#!/usr/bin/env ruby

# Script para gerar tokens de API com permissões completas
# Uso: ruby scripts/generate_api_token.rb

require_relative '../config/environment'

def generate_super_admin_token
  puts "Gerando token de Super Admin..."
  
  # Criar usuário super admin
  super_admin = User.find_or_create_by(email: 'superadmin@api.com') do |user|
    user.password = 'superadmin123!'
    user.password_confirmation = 'superadmin123!'
    user.admin = true
  end

  # Gerar token JWT válido por 1 ano
  payload = {
    user_id: super_admin.id,
    email: super_admin.email,
    admin: true,
    exp: 1.year.from_now.to_i
  }
  
  secret_key = ENV['JWT_SECRET_KEY'] || 'default-secret-key-change-in-production'
  token = JWT.encode(payload, secret_key, 'HS256')
  
  puts "=" * 60
  puts "SUPER ADMIN API TOKEN"
  puts "=" * 60
  puts "Email: #{super_admin.email}"
  puts "Admin: #{super_admin.admin?}"
  puts "Expira em: #{Time.at(payload[:exp])}"
  puts "Token: #{token}"
  puts "=" * 60
  puts "Use no header: Authorization: Bearer #{token}"
  puts "=" * 60
  
  return token
end

def generate_regular_token(email = nil)
  puts "Gerando token de usuário regular..."
  
  email ||= "user_#{SecureRandom.hex(4)}@api.com"
  
  # Criar usuário regular
  user = User.find_or_create_by(email: email) do |u|
    u.password = SecureRandom.hex(12)
    u.password_confirmation = u.password
    u.admin = false
  end

  # Gerar token JWT válido por 30 dias
  payload = {
    user_id: user.id,
    email: user.email,
    admin: false,
    exp: 30.days.from_now.to_i
  }
  
  secret_key = ENV['JWT_SECRET_KEY'] || 'default-secret-key-change-in-production'
  token = JWT.encode(payload, secret_key, 'HS256')
  
  puts "=" * 60
  puts "REGULAR USER API TOKEN"
  puts "=" * 60
  puts "Email: #{user.email}"
  puts "Admin: #{user.admin?}"
  puts "Expira em: #{Time.at(payload[:exp])}"
  puts "Token: #{token}"
  puts "=" * 60
  puts "Use no header: Authorization: Bearer #{token}"
  puts "=" * 60
  
  return token
end

def list_all_tokens
  puts "=" * 60
  puts "TODOS OS TOKENS DISPONÍVEIS"
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

# Execução principal
if ARGV.empty?
  puts "Uso: ruby scripts/generate_api_token.rb [super|regular|list] [email]"
  puts ""
  puts "Comandos disponíveis:"
  puts "  super    - Gerar token de super admin"
  puts "  regular  - Gerar token de usuário regular"
  puts "  list     - Listar todos os tokens"
  puts ""
  puts "Exemplos:"
  puts "  ruby scripts/generate_api_token.rb super"
  puts "  ruby scripts/generate_api_token.rb regular"
  puts "  ruby scripts/generate_api_token.rb regular meu@email.com"
  puts "  ruby scripts/generate_api_token.rb list"
  exit
end

command = ARGV[0]
email = ARGV[1]

case command
when 'super'
  generate_super_admin_token
when 'regular'
  generate_regular_token(email)
when 'list'
  list_all_tokens
else
  puts "Comando inválido: #{command}"
  puts "Use: super, regular, ou list"
end 