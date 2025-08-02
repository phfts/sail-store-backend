class Store < ApplicationRecord
  has_many :sellers, dependent: :destroy
  has_many :shifts, dependent: :destroy
  has_many :schedules, dependent: :destroy
  has_many :vacations, through: :sellers
  
  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true, format: { with: /\A[a-z0-9-]+\z/, message: "deve conter apenas letras minúsculas, números e hífens" }
  
  before_validation :generate_slug, on: :create
  
  private
  
  def generate_slug
    return if slug.present?
    
    base_slug = name.parameterize
    counter = 1
    new_slug = base_slug
    
    while Store.exists?(slug: new_slug)
      new_slug = "#{base_slug}-#{counter}"
      counter += 1
    end
    
    self.slug = new_slug
  end
end
