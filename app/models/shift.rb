class Shift < ApplicationRecord
  belongs_to :store
  has_many :schedules, dependent: :destroy
  has_many :sellers, through: :schedules

  validates :name, presence: true
  validates :start_time, presence: true
  validates :end_time, presence: true
  validate :end_time_after_start_time

  # Override as_json to format time fields properly
  def as_json(options = {})
    super(options).merge({
      'start_time' => start_time&.strftime('%H:%M'),
      'end_time' => end_time&.strftime('%H:%M')
    })
  end

  private

  def end_time_after_start_time
    return if start_time.blank? || end_time.blank?

    # Permitir turnos que atravessam a meia-noite (ex: 20:00 - 02:00)
    # Nesse caso, end_time será menor que start_time
    if end_time <= start_time && end_time.hour > 6
      errors.add(:end_time, "deve ser posterior ao horário de início")
    end
  end
end
