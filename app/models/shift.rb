class Shift < ApplicationRecord
  belongs_to :store
  has_many :schedules, dependent: :destroy
  has_many :sellers, through: :schedules

  validates :name, presence: true
  validates :start_time, presence: true
  validates :end_time, presence: true
  validate :end_time_after_start_time

  private

  def end_time_after_start_time
    return if start_time.blank? || end_time.blank?

    if end_time <= start_time
      errors.add(:end_time, "deve ser posterior ao horário de início")
    end
  end
end
