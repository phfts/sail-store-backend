class Adjustment < ApplicationRecord
  belongs_to :seller
  belongs_to :store
  belongs_to :company
  
  validates :amount, presence: true, numericality: true
  validates :description, presence: true, length: { minimum: 5 }
  validates :date, presence: true
  validates :seller_id, presence: true
  validates :store_id, presence: true
  validates :company_id, presence: true
  
  # Validar que o vendedor pertence à loja
  validate :seller_belongs_to_store
  
  # Validar que a loja pertence à empresa
  validate :store_belongs_to_company
  
  # Callback para definir store_id e company_id automaticamente
  before_validation :set_store_and_company_from_seller
  
  # Scopes
  scope :positive, -> { where('amount > 0') }
  scope :negative, -> { where('amount < 0') }
  scope :for_seller, ->(seller_id) { where(seller_id: seller_id) }
  scope :for_store, ->(store_id) { where(store_id: store_id) }
  scope :for_company, ->(company_id) { where(company_id: company_id) }
  scope :recent, -> { order(created_at: :desc) }
  scope :by_date, ->(date) { where(date: date) }
  scope :by_date_range, ->(start_date, end_date) { where(date: start_date..end_date) }
  scope :this_month, -> { where(date: Date.current.beginning_of_month..Date.current.end_of_month) }
  
  # Métodos de classe
  def self.total_for_seller(seller_id)
    for_seller(seller_id).sum(:amount)
  end
  
  def self.total_for_store(store_id)
    for_store(store_id).sum(:amount)
  end
  
  def self.total_for_company(company_id)
    for_company(company_id).sum(:amount)
  end
  
  # Métodos de instância
  def positive?
    amount > 0
  end
  
  def negative?
    amount < 0
  end
  
  def formatted_amount
    "R$ #{amount.to_f.abs}"
  end
  
  def formatted_amount_with_sign
    sign = positive? ? '+' : '-'
    "#{sign} R$ #{amount.to_f.abs}"
  end
  
  def adjustment_type
    positive? ? 'credit' : 'debit'
  end
  
  private
  
  def seller_belongs_to_store
    return unless seller && store
    
    unless seller.store_id == store.id
      errors.add(:seller, 'deve pertencer à loja informada')
    end
  end
  
  def store_belongs_to_company
    return unless store && company
    
    unless store.company_id == company.id
      errors.add(:store, 'deve pertencer à empresa informada')
    end
  end
  
  def set_store_and_company_from_seller
    if seller
      self.store_id = seller.store_id
      self.company_id = seller.company_id
    end
  end
end