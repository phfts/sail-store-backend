class Schedule < ApplicationRecord
  belongs_to :seller
  belongs_to :shift
  belongs_to :store

  validates :date, presence: true
  validates :seller_id, uniqueness: { scope: [:shift_id, :date, :store_id] }

  scope :for_date, ->(date) { where(date: date) }
  scope :for_date_range, ->(start_date, end_date) { where(date: start_date..end_date) }
  scope :for_store, ->(store_id) { where(store_id: store_id) }
  scope :future, -> { where('date >= ?', Date.current) }
  scope :past, -> { where('date < ?', Date.current) }
  
  def day_of_week
    date&.wday
  end
  
  def week_number
    date&.cweek
  end
  
  def year
    date&.year
  end
end
