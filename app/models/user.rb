class User < ApplicationRecord
  has_secure_password
  
  has_many :sellers, dependent: :destroy
  has_many :login_logs, dependent: :destroy
  
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, presence: true, length: { minimum: 6 }, on: :create
  
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
  
  def stores
    Store.joins(:sellers).where(sellers: { user_id: id })
  end
  
  def store
    stores.first
  end
  
  def store_slug
    store&.slug
  end
end
