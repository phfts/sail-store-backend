# Script para criar usuário admin da loja Souq Iguatemi em produção
puts "📋 Criando usuário admin da loja em PRODUÇÃO..."

# Encontrar a loja Souq Iguatemi
store = Store.find_by(slug: 'souq-sp-iguatemi-sp')
unless store
  puts "❌ Loja 'souq-sp-iguatemi-sp' não encontrada em produção."
  puts "Lojas disponíveis:"
  Store.all.each { |s| puts "  - #{s.slug}" }
  exit
end

company = store.company
unless company
  puts "❌ Empresa associada à loja não encontrada."
  exit
end

puts "✅ Loja encontrada: #{store.name}"
puts "✅ Empresa: #{company.name}"

# Criar ou encontrar o usuário
user_email = 'admin@souq-iguatemi.com'
user_password = 'SouqAdmin2025!'

# Verificar se já existe
existing_user = User.find_by(email: user_email)
if existing_user
  puts "⚠️ Usuário #{user_email} já existe. Atualizando..."
  user = existing_user
else
  puts "🆕 Criando novo usuário #{user_email}..."
  user = User.new(email: user_email)
end

user.password = user_password
user.password_confirmation = user_password
user.admin = false # Não é admin global
user.store_admin = true # É admin da loja

if user.save
  puts "✅ Usuário criado/atualizado: #{user.email}"
  puts "   ID: #{user.id}"
  puts "   Admin Global: #{user.admin}"
  puts "   Store Admin: #{user.store_admin}"

  # Associar o usuário a um seller da loja (necessário para store.id)
  seller_name = 'Admin Loja Souq Iguatemi'
  seller = Seller.find_or_initialize_by(user: user, store: store, company: company)
  seller.name = seller_name
  seller.whatsapp = '5511999990001' # Telefone exemplo
  seller.external_id = 'ADMIN_SOUQ' # ID externo único

  if seller.save
    puts "✅ Seller criado/atualizado: #{seller.name}"
    puts "   ID: #{seller.id}"
    puts "   External ID: #{seller.external_id}"
    puts "   Store: #{seller.store.name}"
    puts "   Company: #{seller.company.name}"
  else
    puts "❌ Erro ao criar seller: #{seller.errors.full_messages.join(', ')}"
  end

  puts ""
  puts "🎯 CREDENCIAIS PARA LOGIN EM PRODUÇÃO:"
  puts "Email: #{user_email}"
  puts "Senha: #{user_password}"
  puts ""
  puts "🔐 PERMISSÕES:"
  puts "- ✅ Acesso de admin da loja (store_admin: true)"
  puts "- ✅ Vendedor associado à loja Souq Iguatemi"
  puts "- ✅ Acesso restrito apenas à sua loja"
  puts "- ❌ NÃO é admin global (admin: false)"
  puts ""
  puts "🌐 URL de Acesso:"
  puts "https://sail-insight-frontend.vercel.app/souq-sp-iguatemi-sp/dashboard"

else
  puts "❌ Erro ao criar usuário: #{user.errors.full_messages.join(', ')}"
end
