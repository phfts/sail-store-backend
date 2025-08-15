class SellersController < ApplicationController
  before_action :set_seller, only: %i[ show update destroy activate deactivate busy_status ]
  before_action :require_admin!, only: %i[ create update destroy ]
  before_action :ensure_store_access, only: %i[ index by_store_slug show ]

  # GET /sellers
  def index
    # Forçar acesso através do slug da loja
    render json: { error: "Acesso negado. Use /stores/:slug/sellers para acessar vendedores de uma loja específica." }, status: :forbidden
  end

  # GET /stores/:slug/sellers/ranking
  def ranking
    begin
      if current_user.admin?
        # Admins podem acessar qualquer loja
        store = Store.find_by!(slug: params[:slug])
      else
        # Usuários regulares só podem acessar sua própria loja
        store = current_user.store
        unless store&.slug == params[:slug]
          render json: { error: "Acesso negado" }, status: :forbidden
          return
        end
      end
      
      # Parâmetros de filtro
      start_date = params[:start_date] ? Date.parse(params[:start_date]) : nil
      end_date = params[:end_date] ? Date.parse(params[:end_date]) : nil
      period = params[:period] || (start_date && end_date ? 'custom' : 'week')
      
      # Definir período baseado no parâmetro
      case period
      when 'week'
        period_start = Date.current.beginning_of_week
        period_end = Date.current.end_of_week
        previous_period_start = 1.week.ago.beginning_of_week
        previous_period_end = 1.week.ago.end_of_week
      when 'month'
        period_start = Date.current.beginning_of_month
        period_end = Date.current.end_of_month
        previous_period_start = 1.month.ago.beginning_of_month
        previous_period_end = 1.month.ago.end_of_month
      when 'quarter'
        period_start = Date.current.beginning_of_quarter
        period_end = Date.current.end_of_quarter
        previous_period_start = 3.months.ago.beginning_of_quarter
        previous_period_end = 3.months.ago.end_of_quarter
      when 'year'
        period_start = Date.current.beginning_of_year
        period_end = Date.current.end_of_year
        previous_period_start = 1.year.ago.beginning_of_year
        previous_period_end = 1.year.ago.end_of_year
      else
        # Período personalizado
        if start_date && end_date
          period_start = start_date
          period_end = end_date
          # Para período personalizado, vamos usar o mesmo período anterior
          period_duration = (end_date - start_date).to_i
          previous_period_start = start_date - period_duration.days
          previous_period_end = start_date - 1.day
        else
          period_start = Date.current.beginning_of_week
          period_end = Date.current.end_of_week
          previous_period_start = 1.week.ago.beginning_of_week
          previous_period_end = 1.week.ago.end_of_week
        end
      end
      
      # Buscar vendedores ativos da loja
      sellers = store.sellers.includes(:user, :goals, :orders => :order_items)
      active_sellers = sellers.select(&:active?)
      
      # Calcular ranking para o período atual
      current_ranking = calculate_seller_ranking(active_sellers, period_start, period_end)
      
      # Calcular ranking para o período anterior
      previous_ranking = calculate_seller_ranking(active_sellers, previous_period_start, previous_period_end)
      
      # Combinar dados e calcular evolução
      final_ranking = current_ranking.map.with_index do |current_seller, index|
        previous_position = previous_ranking.find_index { |s| s[:seller_id] == current_seller[:seller_id] }
        position_change = previous_position ? previous_position - index : 0
        
        # Buscar dados do vendedor
        seller = active_sellers.find { |s| s.id == current_seller[:seller_id] }
        
        # Calcular comissão baseada no nível de comissão da loja
        commission_data = calculate_commission(seller, store, current_seller[:sales], current_seller[:goal_percentage])
        
        {
          position: index + 1,
          seller: {
            id: seller.id.to_s,
            name: seller.name,
            avatar: nil
          },
          sales: {
            current: current_seller[:sales],
            previous: previous_ranking.find { |s| s[:seller_id] == current_seller[:seller_id] }&.dig(:sales) || 0,
            evolution: calculate_evolution_percentage(
              current_seller[:sales],
              previous_ranking.find { |s| s[:seller_id] == current_seller[:seller_id] }&.dig(:sales) || 0
            )
          },
          goal: {
            target: current_seller[:goal_target],
            current: current_seller[:sales],
            percentage: current_seller[:goal_percentage]
          },
          commission: {
            percentage: commission_data[:percentage],
            amount: commission_data[:amount]
          },
          evolution: {
            position: previous_position ? previous_position + 1 : nil,
            change: position_change
          }
        }
      end
      
      render json: final_ranking
    rescue ActiveRecord::RecordNotFound
      render json: { error: "Loja não encontrada" }, status: :not_found
    rescue Date::Error
      render json: { error: "Data inválida" }, status: :bad_request
    end
  end

  # GET /stores/:slug/sellers
  def by_store_slug
    begin
      if current_user.admin?
        # Admins podem acessar qualquer loja
        store = Store.find_by!(slug: params[:slug])
      else
        # Usuários regulares só podem acessar sua própria loja
        store = current_user.store
        unless store&.slug == params[:slug]
          render json: { error: "Acesso negado" }, status: :forbidden
          return
        end
      end
      
      # Filtrar por status de ativação se especificado
      # Incluir absences para evitar N+1
      sellers = store.company.sellers.includes(:user, :store, :absences)
      
      if params[:include_inactive] == 'true'
        # Incluir todos os vendedores (ativos e inativos)
        @sellers = sellers
      else
        # Apenas vendedores ativos
        @sellers = sellers.select(&:active?)
      end
      
      render json: @sellers.map { |seller| seller_response(seller) }
    rescue ActiveRecord::RecordNotFound
      render json: { error: "Loja não encontrada" }, status: :not_found
    end
  end

  # GET /sellers/1
  def show
    if current_user.admin?
      # Admins podem ver qualquer vendedor
      render json: seller_response(@seller)
    else
      # Usuários regulares só podem ver vendedores da sua loja
      if @seller.store_id == current_user.store_id
        render json: seller_response(@seller)
      else
        render json: { error: "Acesso negado" }, status: :forbidden
      end
    end
  end

  # GET /sellers/by_external_id/:external_id
  def by_external_id
    external_id = params[:external_id]
    
    begin
      if current_user.admin?
        # Admins podem buscar qualquer vendedor
        seller = Seller.find_by!(external_id: external_id)
      else
        # Usuários regulares só podem buscar vendedores da sua empresa
        seller = current_user.store.company.sellers.find_by!(external_id: external_id)
      end
      
      render json: seller_response(seller)
    rescue ActiveRecord::RecordNotFound
      render json: { error: "Vendedor não encontrado" }, status: :not_found
    end
  end

  # POST /sellers
  def create
    # Validar email se fornecido
    if params[:seller][:email].present?
      unless params[:seller][:email] =~ URI::MailTo::EMAIL_REGEXP
        render json: { errors: ['Email inválido'] }, status: :unprocessable_entity
        return
      end
    end

    # Validar senha se fornecida
    if params[:seller][:password].present?
      if params[:seller][:password].length < 6
        render json: { errors: ['Senha deve ter pelo menos 6 caracteres'] }, status: :unprocessable_entity
        return
      end
    end

    # Se for admin da loja, email é obrigatório
    if params[:seller][:store_admin] == 'true' || params[:seller][:store_admin] == true
      if params[:seller][:email].blank?
        render json: { errors: ['Email é obrigatório para administradores da loja'] }, status: :unprocessable_entity
        return
      end
      
      user = User.find_by(email: params[:seller][:email])
      
      if user
        # Usuário existe, verificar se já é vendedor nesta loja
        existing_seller = Seller.find_by(user: user, store_id: params[:seller][:store_id])
        if existing_seller
          render json: { errors: ['Já existe um vendedor com este email nesta loja'] }, status: :unprocessable_entity
          return
        end
        
        # Criar vendedor admin associado ao usuário existente
        @seller = Seller.new(seller_params.merge(user: user, store_admin: true))
      else
        # Usuário não existe, criar novo usuário e vendedor admin
        password = user_password.present? ? user_password : SecureRandom.hex(8)
        
        user = User.create!(
          email: params[:seller][:email],
          password: password
        )
        
        @seller = Seller.new(seller_params.merge(user: user, store_admin: true))
      end
    else
      # Não é admin da loja
      if params[:seller][:email].present?
        user = User.find_by(email: params[:seller][:email])
        
        if user
          # Usuário existe, verificar se já é vendedor nesta loja
          existing_seller = Seller.find_by(user: user, store_id: params[:seller][:store_id])
          if existing_seller
            render json: { errors: ['Já existe um vendedor com este email nesta loja'] }, status: :unprocessable_entity
            return
          end
          
          # Criar vendedor associado ao usuário existente
          @seller = Seller.new(seller_params.merge(user: user))
        else
          # Usuário não existe, criar novo usuário e vendedor
          password = user_password.present? ? user_password : SecureRandom.hex(8)
          
          user = User.create!(
            email: params[:seller][:email],
            password: password
          )
          
          @seller = Seller.new(seller_params.merge(user: user))
        end
      else
        # Sem email, criar apenas vendedor com nome
        @seller = Seller.new(seller_params)
      end
    end

    if @seller.save
      render json: seller_response(@seller), status: :created
    else
      render_validation_errors(@seller)
    end
  end

  # PATCH/PUT /sellers/1
  def update
    # Se a flag deactivate estiver presente, definir active_until como agora
    if params[:seller][:deactivate] == 'true'
      params[:seller][:active_until] = Time.current
    end
    
    # Remover a flag deactivate dos parâmetros antes de salvar
    update_params = seller_params.except(:deactivate)
    
    if @seller.update(update_params)
      render json: seller_response(@seller)
    else
      render_validation_errors(@seller)
    end
  end
  
  # PATCH /sellers/1/deactivate
  def deactivate
    begin
      deactivation_date = params[:deactivation_date] ? Time.parse(params[:deactivation_date]) : Time.current
      @seller.deactivate!(deactivation_date)
      render json: { message: 'Vendedor inativado com sucesso', seller: seller_response(@seller) }
    rescue ArgumentError
      render json: { error: 'Data de inativação inválida' }, status: :unprocessable_entity
    rescue => e
      render json: { error: 'Erro ao inativar vendedor' }, status: :unprocessable_entity
    end
  end
  
  # PATCH /sellers/1/activate
  def activate
    @seller.activate!
    render json: { message: 'Vendedor ativado com sucesso', seller: seller_response(@seller) }
  end

  # PUT /sellers/1/busy_status
  def busy_status
    is_busy = params[:is_busy]
    
    # Validar parâmetro is_busy
    if is_busy.nil?
      render json: { error: 'Parâmetro is_busy é obrigatório' }, status: :unprocessable_entity
      return
    end
    
    # Converter para boolean
    busy_value = ActiveModel::Type::Boolean.new.cast(is_busy)
    
    begin
      @seller.update!(is_busy: busy_value)
      status_text = busy_value ? 'ocupado' : 'disponível'
      render json: { 
        message: "Vendedor marcado como #{status_text} com sucesso", 
        seller: seller_response(@seller) 
      }
    rescue => e
      render json: { error: 'Erro ao atualizar status do vendedor' }, status: :unprocessable_entity
    end
  end

  # DELETE /sellers/1
  def destroy
    @seller.destroy
    render json: { message: 'Vendedor excluído com sucesso' }
  end



  private

  def calculate_seller_ranking(sellers, start_date, end_date)
    sellers.map do |seller|
      # Calcular vendas do vendedor no período
      seller_orders = seller.orders.includes(:order_items)
                           .where('orders.sold_at >= ? AND orders.sold_at <= ?', start_date.to_date, end_date.to_date)
      
      sales = seller_orders.sum do |order|
        order.order_items.sum { |item| item.quantity * item.unit_price }
      end
      
      # Buscar meta do vendedor para o período
      goal = seller.goals.where('start_date <= ? AND end_date >= ?', end_date, start_date).first
      goal_target = goal&.target_value || 0
      goal_percentage = goal_target > 0 ? ((sales.to_f / goal_target) * 100).round(2) : 0
      
      {
        seller_id: seller.id,
        sales: sales,
        goal_target: goal_target,
        goal_percentage: goal_percentage
      }
    end.sort_by { |seller_data| -seller_data[:sales] }
  end

  def calculate_commission(seller, store, sales, goal_percentage)
    # Buscar níveis de comissão da loja
    commission_levels = store.commission_levels.active.ordered_by_achievement
    
    # Determinar o nível de comissão baseado no percentual de meta atingido
    commission_level = commission_levels.reverse.find { |level| goal_percentage >= level.achievement_percentage }
    
    if commission_level
      commission_percentage = commission_level.commission_percentage
      commission_amount = (sales * commission_percentage / 100.0).round(2)
    else
      # Sem comissão se não atingir nenhum nível
      commission_percentage = 0.0
      commission_amount = 0.0
    end
    
    {
      percentage: commission_percentage,
      amount: commission_amount
    }
  end

  def calculate_evolution_percentage(current, previous)
    return 0 if previous == 0
    ((current - previous) / previous.to_f * 100).round(2)
  end

  def set_seller
    if current_user.admin?
      @seller = Seller.find(params[:id])
    else
      @seller = current_user.store.sellers.find(params[:id])
    end
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Vendedor não encontrado" }, status: :not_found
  end

  def seller_params
    params.require(:seller).permit(:user_id, :store_id, :company_id, :name, :whatsapp, :email, :store_admin, :active_until, :deactivate, :external_id)
  end

  def user_password
    params[:seller][:password]
  end

  def ensure_store_access
    # Admins têm acesso a todas as lojas
    return if current_user.admin?
    
    # Usuários regulares precisam ter acesso à loja
    unless current_user.store
      render json: { error: "Acesso negado" }, status: :forbidden
    end
  end

  def seller_response(seller)
    {
      id: seller.id,
      user_id: seller.user_id,
      store_id: seller.store_id,
      name: seller.name,
      store_admin: seller.store_admin?,
      active: seller.active?,
      active_until: seller.active_until,
      is_busy: seller.is_busy,
      is_absent: seller.absent?,
      current_absence: seller.current_absence ? {
        id: seller.current_absence.id,
        absence_type: seller.current_absence.absence_type,
        start_date: seller.current_absence.start_date,
        end_date: seller.current_absence.end_date,
        reason: seller.current_absence.reason,
        description: seller.current_absence.description
      } : nil,
      external_id: seller.external_id,
      user: seller.user ? {
        id: seller.user.id,
        email: seller.user.email,
        admin: seller.user.admin?
      } : nil,
      store: {
        id: seller.store.id,
        name: seller.store.name,
        slug: seller.store.slug
      },
      whatsapp: seller.whatsapp_numbers_only,
      email: seller.email,
      formatted_whatsapp: seller.formatted_whatsapp,
      display_name: seller.display_name,
      created_at: seller.created_at,
      updated_at: seller.updated_at
    }
  end
end
