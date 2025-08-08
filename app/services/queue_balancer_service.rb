class QueueBalancerService
  attr_reader :store_id, :company_id
  
  def initialize(store_id)
    @store_id = store_id
    store = Store.find(store_id)
    @company_id = store.company_id
  end
  
  # Encontra o vendedor ótimo para o próximo atendimento
  def find_optimal_seller
    available_sellers = get_available_sellers
    return nil if available_sellers.empty?
    
    # Encontrar o vendedor com menor carga de trabalho
    seller_workloads = available_sellers.map do |seller|
      {
        seller: seller,
        workload: get_seller_workload(seller.id)
      }
    end
    
    # Ordenar por menor carga de trabalho
    optimal = seller_workloads.min_by { |sw| sw[:workload] }
    optimal[:seller]
  end
  
  # Distribui todos os clientes em espera de forma equilibrada
  def distribute_all_customers
    waiting_items = get_waiting_items
    available_sellers = get_available_sellers
    
    return { success: false, message: 'Nenhum cliente em espera' } if waiting_items.empty?
    return { success: false, message: 'Nenhum vendedor disponível' } if available_sellers.empty?
    
    assignments = []
    errors = []
    
    waiting_items.each_with_index do |item, index|
      # Usar algoritmo round-robin para distribuição equilibrada
      seller = available_sellers[index % available_sellers.count]
      
      begin
        item.assign_to_seller!(seller)
        assignments << {
          queue_item_id: item.id,
          seller_id: seller.id,
          seller_name: seller.display_name
        }
      rescue => e
        errors << {
          queue_item_id: item.id,
          error: e.message
        }
      end
    end
    
    {
      success: true,
      message: "#{assignments.count} clientes distribuídos",
      assignments: assignments,
      errors: errors
    }
  end
  
  # Atribui automaticamente o próximo cliente ao vendedor ótimo
  def auto_assign_next_customer
    next_item = get_next_waiting_item
    return { success: false, message: 'Nenhum cliente em espera' } if next_item.nil?
    
    optimal_seller = find_optimal_seller
    return { success: false, message: 'Nenhum vendedor disponível' } if optimal_seller.nil?
    
    begin
      next_item.assign_to_seller!(optimal_seller)
      {
        success: true,
        message: 'Cliente atribuído automaticamente',
        queue_item_id: next_item.id,
        seller_id: optimal_seller.id,
        seller_name: optimal_seller.display_name
      }
    rescue => e
      { success: false, message: e.message }
    end
  end
  
  # Verifica se há desbalanceamento entre vendedores
  def check_balance
    available_sellers = get_available_sellers
    return { balanced: true, sellers: [] } if available_sellers.count < 2
    
    workloads = available_sellers.map do |seller|
      {
        seller_id: seller.id,
        seller_name: seller.display_name,
        workload: get_seller_workload(seller.id)
      }
    end
    
    max_workload = workloads.map { |w| w[:workload] }.max
    min_workload = workloads.map { |w| w[:workload] }.min
    difference = max_workload - min_workload
    
    # Se a diferença for maior que 1, há desbalanceamento
    {
      balanced: difference <= 1,
      difference: difference,
      max_workload: max_workload,
      min_workload: min_workload,
      sellers: workloads,
      overloaded_sellers: workloads.select { |w| w[:workload] == max_workload }
    }
  end
  
  # Obtém estatísticas de performance dos vendedores
  def seller_performance_stats
    available_sellers = get_available_sellers
    today = Date.current
    
    stats = available_sellers.map do |seller|
      completed_today = QueueItem.for_seller(seller.id)
                                 .for_store(store_id)
                                 .completed
                                 .where(completed_at: today.beginning_of_day..today.end_of_day)
      
      current_items = QueueItem.for_seller(seller.id)
                               .for_store(store_id)
                               .in_service
      
      {
        seller_id: seller.id,
        seller_name: seller.display_name,
        is_busy: seller.is_busy || false,
        current_workload: current_items.count,
        completed_today: completed_today.count,
        average_service_time: calculate_average_service_time(completed_today),
        current_customer: current_items.first&.id
      }
    end
    
    # Adicionar vendedores ocupados manualmente
    busy_sellers = get_busy_sellers
    busy_stats = busy_sellers.map do |seller|
      {
        seller_id: seller.id,
        seller_name: seller.display_name,
        is_busy: true,
        status: 'manually_busy',
        current_workload: 0,
        completed_today: 0,
        average_service_time: 0,
        current_customer: nil
      }
    end
    
    # Adicionar vendedores ausentes
    absent_sellers = get_absent_sellers
    absent_stats = absent_sellers.map do |seller|
      {
        seller_id: seller.id,
        seller_name: seller.display_name,
        is_absent: true,
        status: 'absent',
        current_absence: seller.current_absence,
        current_workload: 0,
        completed_today: 0,
        average_service_time: 0,
        current_customer: nil
      }
    end
    
    {
      available_sellers: stats,
      busy_sellers: busy_stats,
      absent_sellers: absent_stats,
      total_available: stats.count,
      total_busy: busy_stats.count,
      total_absent: absent_stats.count
    }
  end
  
  private
  
  def get_available_sellers
    Seller.joins(:store)
          .left_joins(:absences)
          .where(store: { id: store_id })
          .where(stores: { company_id: company_id })
          .where(sellers: { is_busy: [false, nil] })
          .where('sellers.active_until IS NULL OR sellers.active_until > ?', Time.current)
          .where('absences.id IS NULL OR NOT (absences.start_date <= ? AND absences.end_date >= ?)', Date.current, Date.current)
  end
  
  def get_busy_sellers
    Seller.joins(:store)
          .where(store: { id: store_id })
          .where(stores: { company_id: company_id })
          .where(sellers: { is_busy: true })
          .where('sellers.active_until IS NULL OR sellers.active_until > ?', Time.current)
  end
  
  def get_absent_sellers
    Seller.joins(:store)
          .joins(:absences)
          .where(store: { id: store_id })
          .where(stores: { company_id: company_id })
          .where('sellers.active_until IS NULL OR sellers.active_until > ?', Time.current)
          .where('absences.start_date <= ? AND absences.end_date >= ?', Date.current, Date.current)
  end
  
  def get_seller_workload(seller_id)
    QueueItem.for_seller(seller_id)
             .for_store(store_id)
             .in_service
             .count
  end
  
  def get_waiting_items
    QueueItem.for_store(store_id)
             .for_company(company_id)
             .waiting
             .ordered_by_priority
  end
  
  def get_next_waiting_item
    QueueItem.next_in_queue(store_id)
  end
  
  def calculate_average_service_time(completed_items)
    return 0 if completed_items.empty?
    
    total_time = completed_items.sum do |item|
      next 0 unless item.started_at && item.completed_at
      item.completed_at - item.started_at
    end
    
    (total_time / completed_items.count).to_i
  end
end