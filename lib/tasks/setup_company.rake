namespace :setup do
  desc "Setup default company and associate existing data"
  task company: :environment do
    puts "🏢 Configurando empresa padrão..."
    
    # Criar company padrão
    company = Company.find_or_create_by(name: "Souq") do |c|
      c.slug = "souq"
      c.active = true
      c.address = "Endereço da Souq"
    end
    
    puts "✅ Company criada/atualizada: #{company.name} (ID: #{company.id})"
    
    # Associar stores existentes
    stores_count = Store.where(company_id: nil).count
    if stores_count > 0
      Store.where(company_id: nil).update_all(company_id: company.id)
      puts "✅ #{stores_count} stores associadas à company"
    end
    
    # Associar sellers existentes
    sellers_count = Seller.where(company_id: nil).count
    if sellers_count > 0
      Seller.where(company_id: nil).update_all(company_id: company.id)
      puts "✅ #{sellers_count} sellers associados à company"
    end
    
    # Associar categories existentes
    categories_count = Category.where(company_id: nil).count
    if categories_count > 0
      Category.where(company_id: nil).update_all(company_id: company.id)
      puts "✅ #{categories_count} categories associadas à company"
    end
    
    puts "🎉 Setup da company concluído!"
  end
end 