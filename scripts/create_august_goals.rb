#!/usr/bin/env ruby

# Script para cadastrar metas de agosto para vendedores da loja de Iguatemi
# Executar em produção: heroku run rails runner scripts/create_august_goals.rb

puts "🚀 Iniciando cadastro de metas de agosto para vendedores da loja de Iguatemi..."

# Buscar a loja de Iguatemi
store = Store.find_by("name ILIKE ?", "%iguatemi%")

if store.nil?
  puts "❌ Loja de Iguatemi não encontrada!"
  puts "Lojas disponíveis:"
  Store.all.each { |s| puts "  - #{s.name} (ID: #{s.id})" }
  exit 1
end

puts "✅ Loja encontrada: #{store.name} (ID: #{store.id})"

# Lista de vendedores com metas (nomes exatos de produção)
vendedores_metas = [
  "MARIA LIGIA DA SILVA",
  "JESSIELE FIRMINO DOS SANTOS", 
  "ELAINE DIOGO PAULO",
  "NATHALIA DIONISIO MALAQUIAS",
  "MARIA SANDRA VIEIRA DOS SANTOS LIMEIRA",
  "BARBARA DA SILVA GUIMARAES"
]

meta_valor = 59334.00 # R$ 59.334,00
data_inicio = Date.new(2024, 8, 1)
data_fim = Date.new(2024, 8, 31)

puts "📅 Período: #{data_inicio.strftime('%d/%m/%Y')} a #{data_fim.strftime('%d/%m/%Y')}"
puts "💰 Meta por vendedor: R$ #{meta_valor.to_f.round(2)}"
puts ""

# Buscar e criar metas para cada vendedor
vendedores_metas.each do |nome_vendedor|
  puts "🔍 Buscando vendedor: #{nome_vendedor}"
  
  # Buscar vendedor por nome (case insensitive)
  seller = store.sellers.find_by("UPPER(name) = ?", nome_vendedor.upcase)
  
  if seller.nil?
    puts "  ❌ Vendedor não encontrado: #{nome_vendedor}"
    next
  end
  
  puts "  ✅ Vendedor encontrado: #{seller.name} (ID: #{seller.id})"
  
  # Verificar se já existe meta para agosto
  existing_goal = seller.goals.where(
    start_date: data_inicio,
    end_date: data_fim
  ).first
  
  if existing_goal
    puts "  ⚠️  Meta já existe para agosto (ID: #{existing_goal.id})"
    puts "  📝 Atualizando meta existente..."
    
    existing_goal.update!(
      target_value: meta_valor,
      goal_type: 'sales',
      goal_scope: 'individual'
    )
    
    puts "  ✅ Meta atualizada: R$ #{existing_goal.target_value.to_f.round(2)}"
  else
    puts "  📝 Criando nova meta..."
    
    new_goal = seller.goals.create!(
      target_value: meta_valor,
      start_date: data_inicio,
      end_date: data_fim,
      goal_type: 'sales',
      goal_scope: 'individual'
    )
    
    puts "  ✅ Meta criada (ID: #{new_goal.id}): R$ #{new_goal.target_value.to_f.round(2)}"
  end
  
  puts ""
end

puts "🎉 Processo concluído!"
puts ""
puts "📊 Resumo das metas criadas/atualizadas:"

# Listar todas as metas de agosto da loja
goals = Goal.joins(:seller)
           .where(sellers: { store_id: store.id })
           .where(start_date: data_inicio, end_date: data_fim)
           .includes(:seller)

goals.each do |goal|
  puts "  - #{goal.seller.name}: R$ #{goal.target_value.to_f.round(2)} (ID: #{goal.id})"
end

puts ""
puts "Total de metas: #{goals.count}"
puts "Valor total das metas: R$ #{goals.sum(:target_value).to_f.round(2)}"
