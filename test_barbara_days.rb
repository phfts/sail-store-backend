barbara = Seller.joins(:store).where('sellers.name ILIKE ? AND stores.name ILIKE ?', '%barbara%', '%iguatemi%').first
puts "Barbara: #{barbara.name} (ID: #{barbara.id})"

current_date = Date.current
active_goal = barbara.goals.where('start_date <= ? AND end_date >= ?', current_date, current_date).first

if active_goal
  puts "\nMeta ativa: #{active_goal.start_date} a #{active_goal.end_date}"
  
  # Simular o método calculate_goal_days_remaining
  calendar_days_remaining = [active_goal.end_date - current_date, 0].max.to_i
  scheduled_days = barbara.schedules.where(date: current_date..active_goal.end_date).count
  
  puts "\nCálculos:"
  puts "- Dias restantes no calendário: #{calendar_days_remaining}"
  puts "- Dias escalados restantes: #{scheduled_days}"
  
  # Aplicar a lógica do método
  if scheduled_days > 0
    goal_days_remaining = scheduled_days
    puts "- RESULTADO: Usando dias escalados (#{goal_days_remaining})"
  else
    working_days = (current_date..active_goal.end_date).count { |date| !date.sunday? }
    goal_days_remaining = working_days
    puts "- RESULTADO: Usando dias úteis (#{goal_days_remaining})"
  end
  
  puts "\n✅ Barbara deveria ter #{goal_days_remaining} dias restantes"
  puts "❌ Mas a API está retornando 9 dias restantes"
end
