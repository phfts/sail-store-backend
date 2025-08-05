class Category < ApplicationRecord
  has_many :products, dependent: :destroy
  
  validates :external_id, presence: true, uniqueness: true
  validates :name, presence: true
end
