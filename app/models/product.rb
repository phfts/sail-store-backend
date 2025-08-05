class Product < ApplicationRecord
  belongs_to :category
  has_many :order_items, dependent: :destroy
  has_many :orders, through: :order_items
  
  validates :external_id, presence: true, uniqueness: true
  validates :name, presence: true
end
