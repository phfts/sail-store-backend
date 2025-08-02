# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: "Star Wars" }, { name: "Lord of the Rings" }])
#   Character.create(name: "Luke", movie: movies.first)

# Criar usuário admin inicial
admin_email = 'admin@sail.com'
admin_password = 'admin123'

# Verificar se o admin já existe
admin = User.find_by(email: admin_email)

unless admin
  admin = User.create!(
    email: admin_email,
    password: admin_password,
    admin: true
  )
  puts "✅ Usuário admin criado: #{admin.email}"
  puts "🔑 Senha: #{admin_password}"
else
  puts "✅ Usuário admin já existe: #{admin.email}"
end

# Criar turnos de exemplo se não existirem
if Store.exists?
  store = Store.first
  
  unless store.shifts.exists?
    shifts = [
      { name: "Manhã", start_time: "08:00", end_time: "14:00" },
      { name: "Tarde", start_time: "14:00", end_time: "20:00" },
      { name: "Noite", start_time: "20:00", end_time: "02:00" }
    ]

    shifts.each do |shift_attrs|
      store.shifts.create!(shift_attrs)
    end
    
    puts "✅ Turnos de exemplo criados para #{store.name}"
    puts "🕐 Turnos criados: #{store.shifts.count}"
  else
    puts "✅ Turnos já existem para #{store.name}"
  end
else
  puts "⚠️ Nenhuma loja encontrada. Crie uma loja primeiro."
end
