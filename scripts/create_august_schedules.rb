#!/usr/bin/env ruby

# Script para criar escalas de agosto para vendedores com meta
# Executar em produção: heroku run rails runner scripts/create_august_schedules.rb

puts "🚀 Iniciando criação de escalas de agosto para vendedores com meta..."

# Buscar a loja de Iguatemi
store = Store.find_by("name ILIKE ?", "%iguatemi%")

if store.nil?
  puts "❌ Loja de Iguatemi não encontrada!"
  puts "Lojas disponíveis:"
  Store.all.each { |s| puts "  - #{s.name} (ID: #{s.id})" }
  exit 1
end

puts "✅ Loja encontrada: #{store.name} (ID: #{store.id})"

# Buscar vendedores com meta de agosto
august_goals = Goal.joins(:seller)
                   .where(sellers: { store_id: store.id })
                   .where(start_date: Date.new(2024, 8, 1), end_date: Date.new(2024, 8, 31))
                   .includes(:seller)

if august_goals.empty?
  puts "❌ Nenhuma meta de agosto encontrada!"
  exit 1
end

sellers_with_goals = august_goals.map(&:seller).uniq
puts "📋 Vendedores com meta de agosto: #{sellers_with_goals.count}"
sellers_with_goals.each { |s| puts "  - #{s.name}" }

# Buscar turnos disponíveis na loja
shifts = store.shifts
if shifts.empty?
  puts "❌ Nenhum turno encontrado na loja!"
  exit 1
end

# Usar o primeiro turno disponível (assumindo que é o turno principal)
shift = shifts.first
puts "⏰ Usando turno: #{shift.name} (ID: #{shift.id})"

# Definir folgas fixas por dia da semana
# 0 = Domingo, 1 = Segunda, 2 = Terça, 3 = Quarta, 4 = Quinta, 5 = Sexta, 6 = Sábado
folgas_fixas = {
  1 => ["MARIA SANDRA VIEIRA DOS SANTOS LIMEIRA", "MARIA LIGIA DA SILVA"],      # Segunda: Sandra e Ligia
  2 => ["ELAINE DIOGO PAULO"],                                                   # Terça: Elaine
  3 => ["NATHALIA DIONISIO MALAQUIAS"],                                         # Quarta: Nathalia
  4 => ["JESSIELE FIRMINO DOS SANTOS"],                                         # Quinta: Jessiele
  5 => ["BARBARA DA SILVA GUIMARAES"]                                           # Sexta: Bárbara
}

puts ""
puts "📅 Folgas fixas configuradas:"
folgas_fixas.each do |dia, vendedores|
  dia_nome = case dia
             when 1 then "Segunda"
             when 2 then "Terça"
             when 3 then "Quarta"
             when 4 then "Quinta"
             when 5 then "Sexta"
             end
  puts "  #{dia_nome}: #{vendedores.join(', ')}"
end

# Período de agosto (1 a 31 de agosto de 2024)
start_date = Date.new(2024, 8, 1)
end_date = Date.new(2024, 8, 31)

puts ""
puts "📅 Período: #{start_date.strftime('%d/%m/%Y')} a #{end_date.strftime('%d/%m/%Y')}"

# Contadores
total_schedules_created = 0
total_schedules_skipped = 0

# Criar escalas para cada dia do mês
(start_date..end_date).each do |date|
  day_of_week = date.wday # 0 = Domingo, 1 = Segunda, etc.
  
  puts ""
  puts "📅 #{date.strftime('%d/%m/%Y')} (#{I18n.l(date, format: '%A')})"
  
  # Verificar se é dia útil (segunda a sexta)
  if day_of_week >= 1 && day_of_week <= 5
    # Vendedores que devem trabalhar neste dia (todos exceto os que têm folga)
    vendedores_folga = folgas_fixas[day_of_week] || []
    vendedores_trabalho = sellers_with_goals.reject { |s| vendedores_folga.include?(s.name) }
    
    puts "  🏢 Vendedores trabalhando: #{vendedores_trabalho.count}"
    vendedores_trabalho.each { |s| puts "    ✅ #{s.name}" }
    
    if vendedores_folga.any?
      puts "  🏖️  Vendedores de folga: #{vendedores_folga.count}"
      vendedores_folga.each { |nome| puts "    🏖️  #{nome}" }
    end
    
    # Criar escalas para os vendedores que devem trabalhar
    vendedores_trabalho.each do |seller|
      # Verificar se já existe escala para este vendedor neste dia
      existing_schedule = Schedule.find_by(
        seller: seller,
        shift: shift,
        date: date
      )
      
      if existing_schedule
        puts "    ⚠️  Escala já existe para #{seller.name}"
        total_schedules_skipped += 1
      else
        # Criar nova escala
        schedule = Schedule.create!(
          seller: seller,
          shift: shift,
          date: date,
          store: store
        )
        puts "    ✅ Escala criada para #{seller.name} (ID: #{schedule.id})"
        total_schedules_created += 1
      end
    end
  else
    puts "  🏖️  Fim de semana - sem escalas"
  end
end

puts ""
puts "🎉 Processo concluído!"
puts ""
puts "📊 Resumo:"
puts "  ✅ Escalas criadas: #{total_schedules_created}"
puts "  ⚠️  Escalas já existentes: #{total_schedules_skipped}"
puts "  📅 Período: #{start_date.strftime('%d/%m/%Y')} a #{end_date.strftime('%d/%m/%Y')}"
puts "  👥 Vendedores escalados: #{sellers_with_goals.count}"

# Mostrar estatísticas por vendedor
puts ""
puts "📈 Estatísticas por vendedor:"
sellers_with_goals.each do |seller|
  total_days = 0
  folga_days = 0
  
  (start_date..end_date).each do |date|
    day_of_week = date.wday
    if day_of_week >= 1 && day_of_week <= 5
      vendedores_folga = folgas_fixas[day_of_week] || []
      if vendedores_folga.include?(seller.name)
        folga_days += 1
      else
        total_days += 1
      end
    end
  end
  
  puts "  #{seller.name}:"
  puts "    📅 Dias úteis: #{total_days}"
  puts "    🏖️  Dias de folga: #{folga_days}"
end
