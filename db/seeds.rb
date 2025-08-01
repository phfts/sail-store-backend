# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Criar usuário admin
admin_user = User.create!(
  name: 'admin',
  email: 'admin@example.com',
  password: 'password123',
  admin: true
)

# Criar alguns usuários de exemplo
User.create!(
  name: 'joao_silva',
  email: 'joao@example.com',
  password: 'password123'
)

User.create!(
  name: 'maria_oliveira',
  email: 'maria@example.com',
  password: 'password123'
)
