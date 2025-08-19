class Seller < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :store
  belongs_to :company
  
  has_many :schedules, dependent: :destroy
  has_many :shifts, through: :schedules
  has_many :absences, dependent: :destroy
  has_many :goals, dependent: :destroy
  has_many :orders, dependent: :destroy
  has_many :queue_items, dependent: :destroy
  has_many :adjustments, dependent: :destroy
  has_many :exchanges, dependent: :destroy
  has_many :returns, through: :orders
  
  validates :store_id, presence: true
  validates :company_id, presence: true
  validates :whatsapp, presence: true, allow_blank: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
  
  # Validação para admin da loja
  validates :email, presence: true, if: :store_admin?
  validates :user_id, presence: true, if: :store_admin?
  
  # Validação para garantir que pelo menos name ou user_id esteja presente
  validates :name, presence: true, unless: :user_id?
  validates :user_id, presence: true, unless: :name?
  
  # Validação de unicidade do user_id por company (um usuário só pode ser seller em uma empresa)
  validates :user_id, uniqueness: { scope: :company_id, message: "já é vendedor nesta empresa" }, if: :user_id?
  
  # Validação de unicidade do name por company
  validates :name, uniqueness: { scope: :company_id, message: "já existe um vendedor com este nome nesta empresa" }, if: :name?
  
  # Validação de unicidade do external_id por company
  validates :external_id, uniqueness: { scope: :company_id, message: "já existe um vendedor com este external_id nesta empresa" }, if: :external_id?
  
  # Validação de formato do WhatsApp (aceita números, espaços, parênteses, hífens)
  validates :whatsapp, format: { 
    with: /\A[\d\s\(\)\-\+]+\z/, 
    message: "deve conter apenas números, espaços, parênteses, hífens e +",
    allow_blank: true
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
    
    # Formata para exibição baseada no código do país
    if numbers_only.length == 11 && !numbers_only.start_with?('1')
      # Número brasileiro sem código do país: (11) 93747-0101
      "(#{numbers_only[0..1]}) #{numbers_only[2..6]}-#{numbers_only[7..10]}"
    elsif numbers_only.length == 12 && numbers_only.start_with?('55')
      # Número brasileiro com código do país: +55 (11) 93747-0101
      local_number = numbers_only[2..-1]
      "+55 (#{local_number[0..1]}) #{local_number[2..6]}-#{local_number[7..10]}"
    elsif numbers_only.length == 13 && numbers_only.start_with?('55')
      # Número brasileiro com código do país (13 dígitos): +55 (11) 93747-0101
      local_number = numbers_only[2..-1]
      "+55 (#{local_number[0..1]}) #{local_number[2..6]}-#{local_number[7..10]}"
    elsif numbers_only.length == 11 && numbers_only.start_with?('1')
      # Número americano: (555) 123-4567
      "(#{numbers_only[1..3]}) #{numbers_only[4..6]}-#{numbers_only[7..10]}"
    elsif numbers_only.length == 12 && numbers_only.start_with?('1')
      # Número americano com código do país: +1 (555) 123-4567
      local_number = numbers_only[1..-1]
      "+1 (#{local_number[0..2]}) #{local_number[3..5]}-#{local_number[6..9]}"
    elsif numbers_only.length == 13 && numbers_only.start_with?('1')
      # Número americano com código do país (13 dígitos): +1 (555) 123-4567
      local_number = numbers_only[1..-1]
      "+1 (#{local_number[0..2]}) #{local_number[3..5]}-#{local_number[6..9]}"
    else
      # Para outros países, retorna o número como está
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
  
  # Método para obter o primeiro nome do vendedor
  def first_name
    return nil unless name.present?
    name.split.first
  end
  
  # Método para verificar se o vendedor está ativo
  def active?
    active_until.nil? || active_until > Time.current
  end
  
  # Método para inativar o vendedor
  def deactivate!(deactivation_date = Time.current)
    update!(active_until: deactivation_date)
  end
  
  # Método para ativar o vendedor
  def activate!
    update!(active_until: nil)
  end

  # Método para verificar ausência atual
  def current_absence
    absences.current.first
  end

  # Método para verificar se está ausente
  def absent?
    current_absence.present?
  end

  # Método para verificar se está ocupado (manual ou atendendo)
  def busy?
    is_busy == true
  end

  # Método para marcar como ocupado
  def mark_as_busy!
    update!(is_busy: true)
  end

  # Método para marcar como disponível
  def mark_as_available!
    update!(is_busy: false)
  end

  # Método para alternar status de ocupado
  def toggle_busy_status!
    update!(is_busy: !is_busy)
  end
  
  private
  
  def whatsapp_length_validation
    return unless whatsapp.present?
    
    numbers_only = whatsapp.gsub(/[^\d]/, '')
    
    # Com código do país, o número pode ter de 10 a 13 dígitos
    if numbers_only.length < 10
      errors.add(:whatsapp, "deve ter pelo menos 10 dígitos")
    elsif numbers_only.length > 13
      errors.add(:whatsapp, "deve ter no máximo 13 dígitos")
    end
  end
  
  def normalize_whatsapp
    return unless whatsapp.present?
    
    # Remove tudo exceto números
    numbers_only = whatsapp.gsub(/[^\d]/, '')
    
    # Se já tem código do país (1-3 dígitos no início), mantém como está
    if numbers_only.length >= 10 && numbers_only.length <= 13
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
