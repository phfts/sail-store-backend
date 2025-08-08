class Company < ApplicationRecord
  has_many :stores, dependent: :destroy
  has_many :sellers, dependent: :destroy
  has_many :categories, dependent: :destroy
  has_many :queue_items, dependent: :destroy
  has_many :adjustments, dependent: :destroy
  
  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true, format: { with: /\A[a-z0-9-]+\z/, message: "deve conter apenas letras minúsculas, números e hífens" }
  
  before_validation :generate_slug, on: :create
  
  private
  
  def generate_slug
    return if slug.present?
    
    base_slug = name.parameterize
    counter = 1
    new_slug = base_slug
    
    while Company.exists?(slug: new_slug)
      new_slug = "#{base_slug}-#{counter}"
      counter += 1
    end
    
    self.slug = new_slug
  end
end 