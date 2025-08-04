class Absence < ApplicationRecord
  belongs_to :seller

  # Enums para tipos de ausência
  enum :absence_type, {
    vacation: 'vacation',      # Férias
    sick_leave: 'sick_leave',  # Atestado
    weekly_off: 'weekly_off',  # Folga semanal
    other: 'other'             # Outro
  }

  validates :start_date, presence: true
  validates :end_date, presence: true
  validates :absence_type, presence: true, inclusion: { in: absence_types.keys }
  validate :end_date_after_start_date
  validate :no_overlapping_absences

  scope :active, -> { where('end_date >= ?', Date.current) }
  scope :for_seller, ->(seller_id) { where(seller_id: seller_id) }
  scope :by_type, ->(type) { where(absence_type: type) }
  scope :current, -> { where('start_date <= ? AND end_date >= ?', Date.current, Date.current) }

  private

  def end_date_after_start_date
    return if start_date.blank? || end_date.blank?

    if end_date < start_date
      errors.add(:end_date, "deve ser posterior ou igual à data de início")
    end
  end

  def no_overlapping_absences
    return if start_date.blank? || end_date.blank?

    overlapping = Absence.where(seller_id: seller_id)
                        .where.not(id: id)
                        .where('(start_date <= ? AND end_date >= ?) OR (start_date <= ? AND end_date >= ?) OR (start_date >= ? AND end_date <= ?)',
                                end_date, start_date, start_date, start_date, start_date, end_date)

    if overlapping.exists?
      errors.add(:base, "já existe um período de ausência sobreposto para este vendedor")
    end
  end
end
