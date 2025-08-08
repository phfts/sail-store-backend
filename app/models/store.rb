class Store < ApplicationRecord
  belongs_to :company
  
  has_many :sellers, dependent: :destroy
  has_many :shifts, dependent: :destroy
  has_many :schedules, dependent: :destroy
  has_many :commission_levels, dependent: :destroy
  has_many :order_items, dependent: :destroy
  has_many :queue_items, dependent: :destroy
  has_many :absences, through: :sellers
  has_many :goals, through: :sellers
  has_many :orders, through: :sellers
  
  validates :company_id, presence: true
  validates :name, presence: true
  validates :slug, presence: true, uniqueness: { scope: :company_id }, format: { with: /\A[a-z0-9-]+\z/, message: "deve conter apenas letras minúsculas, números e hífens" }
  
  before_validation :generate_slug, on: :create
  after_create :create_default_shifts
  
  private
  
  def generate_slug
    return if slug.present?
    
    base_slug = name.parameterize
    counter = 1
    new_slug = base_slug
    
    while Store.exists?(slug: new_slug, company_id: company_id)
      new_slug = "#{base_slug}-#{counter}"
      counter += 1
    end
    
    self.slug = new_slug
  end
  
  def create_default_shifts
    default_shifts = [
      { name: 'Manhã', start_time: '08:00', end_time: '14:00' },
      { name: 'Tarde', start_time: '14:00', end_time: '20:00' },
      { name: 'Noite', start_time: '20:00', end_time: '02:00' }
    ]
    
    default_shifts.each do |shift_attrs|
      shifts.create!(shift_attrs)
    end
    
    puts "✅ Turnos padrão criados para #{name}: #{shifts.pluck(:name).join(', ')}"
  end
end
