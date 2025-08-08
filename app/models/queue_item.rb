class QueueItem < ApplicationRecord
  belongs_to :seller, optional: true
  belongs_to :store
  belongs_to :company
  
  # Status da fila
  WAITING = 'waiting'.freeze
  IN_SERVICE = 'in_service'.freeze
  COMPLETED = 'completed'.freeze
  CANCELLED = 'cancelled'.freeze
  
  VALID_STATUSES = [WAITING, IN_SERVICE, COMPLETED, CANCELLED].freeze
  
  # Prioridades
  NORMAL_PRIORITY = 1
  HIGH_PRIORITY = 2
  
  validates :status, presence: true, inclusion: { in: VALID_STATUSES }
  validates :priority, presence: true, inclusion: { in: [NORMAL_PRIORITY, HIGH_PRIORITY] }
  validates :store_id, presence: true
  validates :company_id, presence: true
  
  # Validações condicionais
  validates :seller_id, presence: true, if: -> { status == IN_SERVICE }
  validates :started_at, presence: true, if: -> { status == IN_SERVICE }
  validates :completed_at, presence: true, if: -> { status.in?([COMPLETED, CANCELLED]) }
  
  # Scopes
  scope :waiting, -> { where(status: WAITING) }
  scope :in_service, -> { where(status: IN_SERVICE) }
  scope :completed, -> { where(status: COMPLETED) }
  scope :cancelled, -> { where(status: CANCELLED) }
  scope :active, -> { where(status: [WAITING, IN_SERVICE]) }
  scope :finished, -> { where(status: [COMPLETED, CANCELLED]) }
  scope :high_priority, -> { where(priority: HIGH_PRIORITY) }
  scope :normal_priority, -> { where(priority: NORMAL_PRIORITY) }
  scope :ordered_by_priority, -> { order(priority: :desc, created_at: :asc) }
  scope :for_store, ->(store_id) { where(store_id: store_id) }
  scope :for_company, ->(company_id) { where(company_id: company_id) }
  scope :for_seller, ->(seller_id) { where(seller_id: seller_id) }
  scope :today, -> { where(created_at: Date.current.beginning_of_day..Date.current.end_of_day) }
  
  # Callbacks
  before_validation :set_company_from_store, if: -> { store.present? && company_id.blank? }
  before_save :set_timestamps
  
  # Métodos de status
  def waiting?
    status == WAITING
  end
  
  def in_service?
    status == IN_SERVICE
  end
  
  def completed?
    status == COMPLETED
  end
  
  def cancelled?
    status == CANCELLED
  end
  
  def active?
    status.in?([WAITING, IN_SERVICE])
  end
  
  def finished?
    status.in?([COMPLETED, CANCELLED])
  end
  
  def high_priority?
    priority == HIGH_PRIORITY
  end
  
  def normal_priority?
    priority == NORMAL_PRIORITY
  end
  
  # Métodos de ação
  def assign_to_seller!(seller)
    raise ArgumentError, "Seller must belong to the same store" unless seller.store_id == store_id
    raise ArgumentError, "Item must be waiting to be assigned" unless waiting?
    
    update!(
      seller: seller,
      status: IN_SERVICE,
      started_at: Time.current
    )
  end
  
  def complete!
    raise ArgumentError, "Item must be in service to be completed" unless in_service?
    
    update!(
      status: COMPLETED,
      completed_at: Time.current
    )
  end
  
  def cancel!
    raise ArgumentError, "Item must be waiting or in service to be cancelled" unless active?
    
    update!(
      status: CANCELLED,
      completed_at: Time.current
    )
  end
  
  def release_from_seller!
    raise ArgumentError, "Item must be in service to be released" unless in_service?
    
    update!(
      seller: nil,
      status: WAITING,
      started_at: nil
    )
  end
  
  # Métodos de tempo
  def wait_time
    return nil unless started_at.present?
    
    if waiting?
      Time.current - created_at
    else
      started_at - created_at
    end
  end
  
  def service_time
    return nil unless started_at.present?
    
    if in_service?
      Time.current - started_at
    elsif finished?
      completed_at - started_at if completed_at.present?
    end
  end
  
  def total_time
    return nil unless finished?
    
    completed_at - created_at if completed_at.present?
  end
  
  # Métodos de formatação
  def priority_label
    case priority
    when HIGH_PRIORITY
      'Alta'
    when NORMAL_PRIORITY
      'Normal'
    else
      'Desconhecida'
    end
  end
  
  def status_label
    case status
    when WAITING
      'Aguardando'
    when IN_SERVICE
      'Em Atendimento'
    when COMPLETED
      'Concluído'
    when CANCELLED
      'Cancelado'
    else
      'Desconhecido'
    end
  end
  
  # Métodos de classe
  def self.next_in_queue(store_id)
    waiting
      .for_store(store_id)
      .ordered_by_priority
      .first
  end
  
  def self.stats_for_store(store_id)
    today_items = for_store(store_id).today
    
    {
      total_waiting: waiting.for_store(store_id).count,
      total_in_service: in_service.for_store(store_id).count,
      total_completed_today: today_items.completed.count,
      total_cancelled_today: today_items.cancelled.count,
      average_wait_time: calculate_average_wait_time(store_id),
      average_service_time: calculate_average_service_time(store_id)
    }
  end
  
  def self.calculate_average_wait_time(store_id)
    completed_today = for_store(store_id).today.completed.where.not(started_at: nil)
    return 0 if completed_today.empty?
    
    total_wait_time = completed_today.sum { |item| item.started_at - item.created_at }
    (total_wait_time / completed_today.count).to_i
  end
  
  def self.calculate_average_service_time(store_id)
    completed_today = for_store(store_id).today.completed.where.not(started_at: nil, completed_at: nil)
    return 0 if completed_today.empty?
    
    total_service_time = completed_today.sum { |item| item.completed_at - item.started_at }
    (total_service_time / completed_today.count).to_i
  end
  
  private
  
  def set_company_from_store
    self.company_id = store.company_id if store.present?
  end
  
  def set_timestamps
    case status
    when IN_SERVICE
      self.started_at = Time.current if started_at.blank?
    when COMPLETED, CANCELLED
      self.completed_at = Time.current if completed_at.blank?
    end
  end
end