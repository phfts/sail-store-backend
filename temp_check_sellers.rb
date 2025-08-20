# Script temporário para verificar vendedores da loja de Iguatemi
store = Store.find_by("name ILIKE ?", "%iguatemi%")

if store.nil?
  puts "❌ Loja de Iguatemi não encontrada!"
  puts "Lojas disponíveis:"
  Store.all.each { |s| puts "  - #{s.name} (ID: #{s.id})" }
  exit 1
end

puts "✅ Loja encontrada: #{store.name} (ID: #{store.id})"
puts "Vendedores da loja de Iguatemi:"
store.sellers.each { |s| puts "  - #{s.name}" }
