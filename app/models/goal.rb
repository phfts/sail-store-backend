class Goal < ApplicationRecord
  belongs_to :seller, optional: true

  enum :goal_type, {
    sales: 0        # Volume de vendas (padrão)
  }, default: :sales

  enum :goal_scope, {
    individual: 0,   # Meta individual por vendedor
    store_wide: 1    # Meta por loja
  }, default: :individual

  before_create :set_initial_current_value

  validates :goal_type, presence: true
  validates :start_date, presence: true
  validates :end_date, presence: true
  validates :target_value, presence: true, numericality: { greater_than: 0 }
  validates :current_value, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :description, length: { maximum: 500 }, allow_blank: true
  
  validate :end_date_after_start_date


  scope :active, -> { where('end_date >= ?', Date.current) }
  scope :completed, -> { where('current_value >= target_value') }
  scope :in_progress, -> { where('current_value < target_value AND end_date >= ?', Date.current) }

  def progress_percentage
    return 0 if target_value.zero?
    ((current_value / target_value) * 100).round(2)
  end

  def is_completed?
    current_value >= target_value
  end

  def is_overdue?
    end_date < Date.current && !is_completed?
  end

  def days_remaining
    return 0 if end_date < Date.current
    (end_date - Date.current).to_i
  end

  private

  def set_initial_current_value
    self.current_value = 0 if current_value.nil?
  end

  def end_date_after_start_date
    return if start_date.blank? || end_date.blank?
    
    if end_date <= start_date
      errors.add(:end_date, "deve ser posterior à data de início")
    end
  end


end
