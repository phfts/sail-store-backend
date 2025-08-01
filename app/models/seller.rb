class Seller < ApplicationRecord
  belongs_to :user
  
  validates :user_id, presence: true
  validates :whatsapp, presence: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
  
  # Validação de unicidade do user_id (um usuário só pode ter um seller)
  validates :user_id, uniqueness: true
  
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
end
