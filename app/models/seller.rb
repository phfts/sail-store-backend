class Seller < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :store
  
  validates :store_id, presence: true
  validates :whatsapp, presence: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
  
  # Validação para admin da loja
  validates :email, presence: true, if: :store_admin?
  validates :user_id, presence: true, if: :store_admin?
  
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
  
  # Validação de comprimento mínimo do WhatsApp (apenas números)
  validate :whatsapp_length_validation
  
  # Callback para normalizar WhatsApp antes de salvar
  before_save :normalize_whatsapp
  
  # Método para formatar WhatsApp para exibição
  def formatted_whatsapp
    return whatsapp unless whatsapp.present?
    
    # Remove tudo exceto números
    numbers_only = whatsapp.gsub(/[^\d]/, '')
    
    # Garante que tenha pelo menos 10 dígitos
    return whatsapp if numbers_only.length < 10
    
    # Formata para exibição: (11) 93747-0101
    if numbers_only.length == 11
      "(#{numbers_only[0..1]}) #{numbers_only[2..6]}-#{numbers_only[7..10]}"
    elsif numbers_only.length == 12 && numbers_only.start_with?('55')
      # Remove código do país para formatação
      local_number = numbers_only[2..-1]
      "(#{local_number[0..1]}) #{local_number[2..6]}-#{local_number[7..10]}"
    elsif numbers_only.length == 13 && numbers_only.start_with?('55')
      # Remove código do país para formatação (caso tenha 13 dígitos)
      local_number = numbers_only[2..-1]
      "(#{local_number[0..1]}) #{local_number[2..6]}-#{local_number[7..10]}"
    else
      whatsapp
    end
  end
  
  # Método para obter apenas números do WhatsApp
  def whatsapp_numbers_only
    return nil unless whatsapp.present?
    whatsapp.gsub(/[^\d]/, '')
  end
  
  # Método para obter o nome do vendedor
  def display_name
    name.presence || user&.email
  end
  
  private
  
  def whatsapp_length_validation
    return unless whatsapp.present?
    
    numbers_only = whatsapp.gsub(/[^\d]/, '')
    
    # Com código do país, o número pode ter de 10 a 15 dígitos
    if numbers_only.length < 10
      errors.add(:whatsapp, "deve ter pelo menos 10 dígitos")
    elsif numbers_only.length > 15
      errors.add(:whatsapp, "deve ter no máximo 15 dígitos")
    end
  end
  
  def normalize_whatsapp
    return unless whatsapp.present?
    
    # Remove tudo exceto números
    numbers_only = whatsapp.gsub(/[^\d]/, '')
    
    # Se já tem código do país (1-3 dígitos no início), mantém como está
    if numbers_only.length >= 10 && numbers_only.length <= 15
      # Verifica se já tem código do país
      country_codes = ['33', '44', '49', '34', '39', '31', '351', '54', '55', '56', '57', '58', '593', '51', '591', '595', '598']
      has_country_code = country_codes.any? { |code| numbers_only.start_with?(code) }
      
      # Trata código '1' separadamente para evitar conflito com números brasileiros
      if numbers_only.start_with?('1') && numbers_only.length >= 10
        # Se começa com 1 e tem pelo menos 10 dígitos, provavelmente é EUA
        # Mas se tem 11 dígitos e o segundo dígito é 1, provavelmente é Brasil (11)
        if numbers_only.length == 11 && numbers_only[1] == '1'
          has_country_code = false
        else
          has_country_code = true
        end
      end
      
      if has_country_code
        # Já tem código do país, mantém como está
        self.whatsapp = numbers_only
      else
        # Não tem código do país, adiciona Brasil como padrão
        if numbers_only.length == 10
          numbers_only = '55' + numbers_only
        elsif numbers_only.length == 11 && numbers_only.start_with?('0')
          numbers_only = '55' + numbers_only[1..-1]
        elsif numbers_only.length == 11
          # Se tem 11 dígitos mas não tem código do país, adiciona Brasil
          numbers_only = '55' + numbers_only
        end
        self.whatsapp = numbers_only
      end
    else
      # Número muito curto ou muito longo, mantém como está
      self.whatsapp = numbers_only
    end
  end
end
