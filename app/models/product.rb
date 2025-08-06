class Product < ApplicationRecord
  belongs_to :category, counter_cache: true
  has_many :order_items, dependent: :destroy
  has_many :orders, through: :order_items
  
  validates :external_id, presence: true, uniqueness: true
  validates :name, presence: true
  validates :sku, presence: true, uniqueness: true
end
