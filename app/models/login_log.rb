class LoginLog < ApplicationRecord
  belongs_to :user
  
  validates :login_at, presence: true
  validates :ip_address, presence: true
  
  scope :recent, -> { where('login_at >= ?', 30.days.ago) }
  scope :this_month, -> { where('login_at >= ?', 1.month.ago) }
  scope :this_week, -> { where('login_at >= ?', 1.week.ago) }
  scope :today, -> { where('login_at >= ?', 1.day.ago) }
  
  def self.unique_users_in_period(period)
    case period
    when :month
      this_month.distinct.count(:user_id)
    when :week
      this_week.distinct.count(:user_id)
    when :day
      today.distinct.count(:user_id)
    else
      0
    end
  end
end
