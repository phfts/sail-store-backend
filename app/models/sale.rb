class Sale < ApplicationRecord
  belongs_to :seller

  validates :value, presence: true, numericality: { greater_than: 0 }
  validates :sold_at, presence: true

  scope :by_date_range, ->(start_date, end_date) { 
    where(sold_at: start_date.beginning_of_day..end_date.end_of_day) 
  }
  
  scope :by_seller, ->(seller_id) { where(seller_id: seller_id) }
  
  scope :recent, -> { order(sold_at: :desc) }

  def formatted_value
    ActionController::Base.helpers.number_to_currency(value, unit: "R$ ", separator: ",", delimiter: ".")
  end

  def formatted_date
    sold_at.strftime("%d/%m/%Y %H:%M")
  end
end
