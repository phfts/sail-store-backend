class Vacation < ApplicationRecord
  belongs_to :seller

  validates :start_date, presence: true
  validates :end_date, presence: true
  validate :end_date_after_start_date
  validate :no_overlapping_vacations

  scope :active, -> { where('end_date >= ?', Date.current) }
  scope :for_seller, ->(seller_id) { where(seller_id: seller_id) }

  private

  def end_date_after_start_date
    return if start_date.blank? || end_date.blank?

    if end_date < start_date
      errors.add(:end_date, "deve ser posterior ou igual à data de início")
    end
  end

  def no_overlapping_vacations
    return if start_date.blank? || end_date.blank?

    overlapping = Vacation.where(seller_id: seller_id)
                         .where.not(id: id)
                         .where('(start_date <= ? AND end_date >= ?) OR (start_date <= ? AND end_date >= ?) OR (start_date >= ? AND end_date <= ?)',
                                 end_date, start_date, start_date, start_date, start_date, end_date)

    if overlapping.exists?
      errors.add(:base, "já existe um período de férias sobreposto para este vendedor")
    end
  end
end
