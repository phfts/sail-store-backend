class Seller < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :store
  
  validates :store_id, presence: true
  validates :whatsapp, presence: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
  
  # Validação para garantir que pelo menos name ou user_id esteja presente
  validates :name, presence: true, unless: :user_id?
  validates :user_id, presence: true, unless: :name?
  
  # Validação de unicidade do user_id por store (um usuário só pode ser seller em uma loja)
  validates :user_id, uniqueness: { scope: :store_id, message: "já é vendedor nesta loja" }, if: :user_id?
  
  # Validação de unicidade do name por store
  validates :name, uniqueness: { scope: :store_id, message: "já existe um vendedor com este nome nesta loja" }, if: :name?
  
  # Validação de formato do WhatsApp (aceita números, espaços, parênteses, hífens)
  validates :whatsapp, format: { 
    with: /\A[\d\s\(\)\-\+]+/, 
    message: "deve conter apenas números, espaços, parênteses, hífens e +" 
  }
  
  # Método para formatar WhatsApp
  def formatted_whatsapp
    # Remove tudo exceto números
    numbers_only = whatsapp.gsub(/[^\d]/, '')
    
    # Adiciona código do país se não tiver
    if numbers_only.length == 11 && numbers_only.start_with?('0')
      numbers_only = '55' + numbers_only[1..-1]
    elsif numbers_only.length == 10
      numbers_only = '55' + numbers_only
    end
    
    numbers_only
  end
  
  # Método para obter o nome do vendedor
  def display_name
    name.presence || user&.name
  end
end
