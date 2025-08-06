class Category < ApplicationRecord
  belongs_to :company
  
  has_many :products, dependent: :destroy
  
  validates :company_id, presence: true
  validates :external_id, presence: true
  validates :name, presence: true
  
  # Validação de unicidade do external_id por company
  validates :external_id, uniqueness: { scope: :company_id, message: "já existe uma categoria com este external_id nesta empresa" }
  
  # Validação de unicidade do name por company
  validates :name, uniqueness: { scope: :company_id, message: "já existe uma categoria com este nome nesta empresa" }
end
