class Schedule < ApplicationRecord
  belongs_to :seller
  belongs_to :shift
  belongs_to :store

  validates :day_of_week, presence: true, inclusion: { in: 0..6 }
  validates :week_number, presence: true, numericality: { greater_than: 0, less_than_or_equal_to: 53 }
  validates :year, presence: true, numericality: { greater_than: 2020 }
  validates :seller_id, uniqueness: { scope: [:shift_id, :day_of_week, :week_number, :year, :store_id] }

  scope :for_week, ->(week_number, year) { where(week_number: week_number, year: year) }
  scope :for_day, ->(day_of_week) { where(day_of_week: day_of_week) }
  scope :for_store, ->(store_id) { where(store_id: store_id) }
end
