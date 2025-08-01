class User < ApplicationRecord
  has_secure_password
  
  validates :name, presence: true, uniqueness: true
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, presence: true, length: { minimum: 6 }, on: :create
  validates :password, length: { minimum: 6 }, allow_blank: true, on: :update
  
  scope :admins, -> { where(admin: true) }
  scope :regular_users, -> { where(admin: false) }
  
  def admin?
    admin == true
  end
  
  def regular_user?
    !admin?
  end
  
  def seller?
    Seller.exists?(user_id: id)
  end
  
  def seller
    Seller.find_by(user_id: id)
  end
end
