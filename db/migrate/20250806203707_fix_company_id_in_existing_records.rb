class FixCompanyIdInExistingRecords < ActiveRecord::Migration[8.0]
  def up
    # Criar uma empresa padrão se não existir
    default_company = Company.find_or_create_by(name: 'Souq') do |company|
      company.slug = 'souq'
      company.active = true
    end

    # Atualizar sellers sem company_id
    execute "UPDATE sellers SET company_id = #{default_company.id} WHERE company_id IS NULL"
    
    # Atualizar categories sem company_id
    execute "UPDATE categories SET company_id = #{default_company.id} WHERE company_id IS NULL"
    
    # Atualizar stores sem company_id
    execute "UPDATE stores SET company_id = #{default_company.id} WHERE company_id IS NULL"
  end

  def down
    # Esta migração não é reversível pois estamos corrigindo dados existentes
  end
end
