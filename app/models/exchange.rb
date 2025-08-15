class Exchange < ApplicationRecord
  # Relacionamentos
  belongs_to :seller, optional: true
  belongs_to :original_order, class_name: 'Order', optional: true
  belongs_to :new_order, class_name: 'Order', optional: true
  
  # Validações
  validates :external_id, presence: true, uniqueness: true
  validates :voucher_number, presence: true
  validates :voucher_value, presence: true, numericality: true
  validates :exchange_type, presence: true
  validates :processed_at, presence: true
  
  # Scopes
  scope :credits, -> { where(is_credit: true) }
  scope :debits, -> { where(is_credit: false) }
  scope :by_date_range, ->(start_date, end_date) { where(processed_at: start_date..end_date) }
  
  # Métodos
  def credit?
    is_credit == true
  end
  
  def debit?
    is_credit == false
  end
  
  def formatted_value
    voucher_value.to_f
  end
end
