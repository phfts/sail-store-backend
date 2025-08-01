# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Criar usuário admin inicial se as variáveis de ambiente estiverem definidas
admin_username = ENV['ADMIN_USERNAME']
admin_password = ENV['ADMIN_PASSWORD']
admin_email = ENV['ADMIN_EMAIL']

if admin_username && admin_password && admin_email
  # Verificar se o admin já existe
  admin = User.find_by(username: admin_username)
  
  unless admin
    admin = User.create!(
      username: admin_username,
      email: admin_email,
      password: admin_password,
      admin: true
    )
    puts "Usuário admin criado: #{admin.username}"
  else
    puts "Usuário admin já existe: #{admin.username}"
  end
else
  puts "Variáveis de ambiente ADMIN_USERNAME, ADMIN_PASSWORD e ADMIN_EMAIL não estão definidas."
  puts "Para criar um usuário admin, defina essas variáveis de ambiente."
end
