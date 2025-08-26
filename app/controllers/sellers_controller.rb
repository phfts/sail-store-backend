class SellersController < ApplicationController
  before_action :set_seller, only: %i[ show update destroy activate deactivate busy_status ]
  before_action :require_admin!, only: %i[ create update destroy ]
  before_action :ensure_store_access, only: %i[ index by_store_slug show ]
  skip_before_action :authenticate_user!, only: %i[ kpis ]

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
            percentage: current_seller[:goal_percentage]
          },
          commission: {
            percentage: commission_data[:percentage],
            amount: commission_data[:amount]
          },
          position_evolution: {
            previous_position: previous_position ? previous_position + 1 : nil,
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
      # Ordenar por queue_order primeiro, depois por nome
      sellers = store.sellers.includes(:user, :store, :absences)
                     .order(:queue_order, :name)
      
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
      if current_user.store && @seller.store_id == current_user.store.id
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

  # GET /sellers/:id/kpis - KPIs baseados nos campos da planilha
  def kpis
    seller_id = params[:id]
    
    # Buscar vendedor específico pelo ID
    seller = Seller.includes(:store, :company, :goals, :orders => :order_items).find(seller_id)
    
    if seller.nil?
      render json: { error: "Nenhum vendedor encontrado" }, status: :not_found
      return
    end
    
    store = seller.store
    current_date = Date.current
    
    # Buscar todas as metas ativas do vendedor
    active_goals = seller.goals.active.order(:start_date)
    
    # Processar cada meta dinamicamente
    goals_data = []
    
    active_goals.each do |goal|
      goal_start = goal.start_date
      goal_end = goal.end_date
      goal_target = goal.target_value
      goal_current_value = goal.current_value || 0
      
      # Calcular vendas líquidas no período da meta
      goal_orders = seller.orders.includes(:order_items)
                         .where('sold_at >= ? AND sold_at <= ?', goal_start, goal_end)
      sales_data = calculate_net_sales(seller, goal_start, goal_end)
      goal_sales = sales_data[:net_sales]
      
      # Calcular métricas do período
      goal_orders_count = goal_orders.count
      goal_total_items = goal_orders.joins(:order_items).sum('order_items.quantity')
      
      # Dias da meta
      goal_total_days = (goal_end - goal_start).to_i + 1
      goal_days_elapsed = [current_date - goal_start + 1, 0].max.to_i
      goal_days_remaining = [goal_end - current_date, 0].max.to_i
      
      # Calcular percentual e métricas
      goal_percentage = goal_target > 0 ? (goal_sales / goal_target * 100).round(2) : 0
      goal_ticket = goal_orders_count > 0 ? goal_sales / goal_orders_count : 0
      goal_pa = goal_orders_count > 0 ? goal_total_items.to_f / goal_orders_count : 0
      
      # Classificar tipo de período
      goal_type = case goal_total_days
                  when 1..7 then 'diario'
                  when 8..14 then 'semanal'
                  when 15..35 then 'mensal'
                  when 36..100 then 'trimestral'
                  else 'personalizado'
                  end
      
      goals_data << {
        id: goal.id,
        tipo: goal_type,
        nome_periodo: "#{goal_type.capitalize} (#{goal_total_days} dias)",
        inicio: goal_start.strftime("%d/%m/%Y"),
        fim: goal_end.strftime("%d/%m/%Y"),
        meta_valor: goal_target,
        vendas_realizadas: goal_sales,
        percentual_atingido: goal_percentage,
        dias_total: goal_total_days,
        dias_decorridos: goal_days_elapsed,
        dias_restantes: goal_days_remaining,
        meta_recalculada_dia: goal_days_remaining > 0 ? ((goal_target - goal_sales) / goal_days_remaining).round(2) : 0,
        ticket_medio: goal_ticket.round(2),
        pa_produtos_atendimento: goal_pa.round(1),
        pedidos_count: goal_orders_count,
        produtos_vendidos: goal_total_items,
        quanto_falta_super_meta: [(goal_target * 1.2) - goal_sales, 0].max.round(2),
        meta_data: {
          inicio_iso: goal_start.iso8601,
          fim_iso: goal_end.iso8601,
          goal_type: goal.goal_type,
          goal_scope: goal.goal_scope
        }
      }
    end
    
    # Se não há metas, calcular dados do mês atual
    if goals_data.empty?
      # Calcular vendas líquidas do mês atual
      current_month_start = current_date.beginning_of_month
      current_month_end = current_date.end_of_month
      current_sales_data = calculate_net_sales(seller, current_month_start, current_month_end)
      
      # Buscar pedidos do mês atual
      current_orders = seller.orders.includes(:order_items)
                           .where('sold_at >= ? AND sold_at <= ?', current_month_start, current_month_end)
      current_orders_count = current_orders.count
      current_total_items = current_orders.joins(:order_items).sum('order_items.quantity')
      
      # Calcular métricas do mês atual
      current_ticket = current_orders_count > 0 ? current_sales_data[:net_sales] / current_orders_count : 0
      current_pa = current_orders_count > 0 ? current_total_items.to_f / current_orders_count : 0
      
      # Calcular dias com vendas para o mês atual
      days_with_sales = calculate_days_with_sales(seller, current_month_start, current_month_end)
      
      # Criar meta fictícia para o mês atual
      current_goal_data = {
        meta_valor: 0,
        vendas_realizadas: current_sales_data[:net_sales],
        percentual_atingido: 0,
        tipo: 'mensal',
        inicio: current_month_start.strftime("%d/%m/%Y"),
        fim: current_month_end.strftime("%d/%m/%Y"),
        dias_restantes: current_month_end.day - current_date.day,
        meta_recalculada_dia: 0,
        ticket_medio: current_ticket,
        pa_produtos_atendimento: current_pa,
        pedidos_count: current_orders_count,
        produtos_vendidos: current_total_items,
        quanto_falta_super_meta: 0
      }
      
      kpi_data = {
        telefone: seller.formatted_whatsapp,
        nome: seller.display_name,
        metas: [],
        meta_principal: current_goal_data,
        loja: {
          total_vendas: 0,
          ticket_medio: 0,
          meta_periodo: 0,
          percentual_atingido: 0,
          pa_produtos_atendimento: 0,
          pedidos_count: 0,
          produtos_vendidos: 0
        },
        vendedor: {
          ticket_medio: current_ticket,
          pa_produtos_atendimento: current_pa,
          comissao_calculada: 0,
          percentual_comissao: 0,
          total_metas_ativas: 0,
          dias_com_vendas: days_with_sales,
          vendas_por_dia: days_with_sales > 0 ? ((current_sales_data[:net_sales] / days_with_sales) / 100.0).round(2) : 0,
          pedidos_por_dia: days_with_sales > 0 ? (current_orders_count.to_f / days_with_sales).round(2) : 0
        },
        commission_levels: [],
        metadados: {
          data_atual: current_date.iso8601,
          total_metas_ativas: 0,
          tipos_metas: [],
          periodo_analise: {
            inicio: current_month_start.iso8601,
            fim: current_month_end.iso8601
          }
        }
      }
      
      render json: kpi_data
      return
    end
    
    # Usar a meta principal (primeira ou maior) para cálculos gerais
    primary_goal = goals_data.first
    monthly_target = primary_goal[:meta_valor].to_f
    monthly_sales = primary_goal[:vendas_realizadas].to_f
    monthly_days_remaining = primary_goal[:dias_restantes]
    
    # Calcular métricas da loja baseado na meta principal
    primary_start = Date.parse(primary_goal[:meta_data][:inicio_iso])
    primary_end = Date.parse(primary_goal[:meta_data][:fim_iso])
    
    store_orders = Order.joins(:seller)
                        .where(sellers: { store_id: store.id })
                        .includes(:order_items)
                        .where('orders.sold_at >= ? AND orders.sold_at <= ?', primary_start, [current_date, primary_end].min)
    store_sales = store_orders.joins(:order_items).sum('order_items.quantity * order_items.unit_price')
    store_orders_count = store_orders.count
    store_total_items = store_orders.joins(:order_items).sum('order_items.quantity')
    # Calcular meta da loja baseada no número real de vendedores ativos
    active_sellers_count = store.sellers.where(active_until: nil).or(store.sellers.where('active_until > ?', current_date)).count
    store_target = monthly_target * [active_sellers_count, 1].max # Mínimo de 1 vendedor
    
    # Calcular KPIs conforme planilha (baseado na meta principal)
    seller_ticket = primary_goal[:ticket_medio]
    store_ticket = store_orders_count > 0 ? store_sales / store_orders_count : 0
    seller_pa = primary_goal[:pa_produtos_atendimento]
    store_pa = store_orders_count > 0 ? store_total_items.to_f / store_orders_count : 0
    
    # Percentuais
    seller_percentage = primary_goal[:percentual_atingido]
    store_percentage = store_target > 0 ? (store_sales / store_target * 100).round(2) : 0
    
    # Comissão - usar commission_levels ou fallback simples
    commission_levels = store.commission_levels.order(:achievement_percentage)
    if commission_levels.any?
      current_level = commission_levels.where('achievement_percentage <= ?', seller_percentage).last
      commission_rate = current_level&.commission_percentage || 3.5
    else
      # Níveis simples baseados em performance
      commission_rate = case seller_percentage
                       when 0..69.99 then 3.5
                       when 70..89.99 then 4.0
                       when 90..109.99 then 4.5
                       else 5.0
                       end
    end
    
    commission_amount = monthly_sales * (commission_rate / 100)
    
    # Calcular dias com vendas para o período da meta principal
    days_with_sales = calculate_days_with_sales(seller, primary_start, [current_date, primary_end].min)
    
    # Dados conforme planilha
    kpi_data = {
      # Campos básicos da planilha
      telefone: seller.formatted_whatsapp,
      nome: seller.display_name,
      
      # === ARRAY DINÂMICO DE METAS ===
      metas: goals_data,
      
      # === DADOS CONSOLIDADOS (baseados na meta principal) ===
      meta_principal: {
        meta_valor: primary_goal[:meta_valor],
        vendas_realizadas: primary_goal[:vendas_realizadas],
        percentual_atingido: primary_goal[:percentual_atingido],
        tipo_periodo: primary_goal[:tipo],
        inicio: primary_goal[:inicio],
        fim: primary_goal[:fim],
        dias_restantes: primary_goal[:dias_restantes],
        meta_recalculada_dia: primary_goal[:meta_recalculada_dia],
        quanto_falta_super_meta: primary_goal[:quanto_falta_super_meta],
        ticket_medio: primary_goal[:ticket_medio],
        pedidos_count: primary_goal[:pedidos_count],
        pa_produtos_atendimento: primary_goal[:pa_produtos_atendimento]
      },
      
      # === DADOS DA LOJA ===
      loja: {
        total_vendas: store_sales,
        ticket_medio: store_ticket.round(2),
        meta_periodo: store_target,
        percentual_atingido: store_percentage,
        pa_produtos_atendimento: store_pa.round(1),
        pedidos_count: store_orders_count,
        produtos_vendidos: store_total_items
      },
      
      # === DADOS DO VENDEDOR ===
      vendedor: {
        ticket_medio: seller_ticket,
        pa_produtos_atendimento: seller_pa,
        comissao_calculada: commission_amount.round(2),
        percentual_comissao: commission_rate,
        total_metas_ativas: goals_data.length,
        dias_com_vendas: days_with_sales,
        vendas_por_dia: days_with_sales > 0 ? ((monthly_sales / days_with_sales) / 100.0).round(2) : 0,
        pedidos_por_dia: days_with_sales > 0 ? (primary_goal[:pedidos_count] / days_with_sales).round(2) : 0
      },
      
      # === NÍVEIS DE COMISSÃO ===
      commission_levels: commission_levels.any? ? 
        commission_levels.map { |cl| { level: cl.achievement_percentage, commission: cl.commission_percentage } } :
        [
          { level: 70.0, commission: 3.5 },
          { level: 80.0, commission: 4.0 },
          { level: 90.0, commission: 4.5 },
          { level: 100.0, commission: 5.0 }
        ],
      
      # === METADADOS ===
      metadados: {
        data_atual: current_date.iso8601,
        total_metas_ativas: goals_data.length,
        tipos_metas: goals_data.map { |g| g[:tipo] }.uniq,
        periodo_analise: {
          inicio: goals_data.map { |g| g[:meta_data][:inicio_iso] }.min,
          fim: goals_data.map { |g| g[:meta_data][:fim_iso] }.max
        }
      }
    }

    render json: kpi_data
  end

  # PUT /stores/:slug/sellers/queue_order
  def update_queue_order
    begin
      if current_user.admin?
        store = Store.find_by!(slug: params[:slug])
      else
        store = current_user.store
        unless store&.slug == params[:slug]
          render json: { error: "Acesso negado" }, status: :forbidden
          return
        end
      end

      seller_orders = params[:seller_orders]
      unless seller_orders.is_a?(Array)
        render json: { error: "seller_orders deve ser um array" }, status: :unprocessable_entity
        return
      end

      # Usar transação para garantir consistência
      ActiveRecord::Base.transaction do
        seller_orders.each_with_index do |seller_data, index|
          seller_id = seller_data[:seller_id] || seller_data['seller_id']
          seller = store.sellers.find(seller_id)
          seller.update!(queue_order: index + 1)
        end
      end

      # Retornar vendedores atualizados
      sellers = store.sellers.includes(:user, :absences)
                     .order(:queue_order, :name)

      sellers_data = sellers.map do |seller|
        current_absence = seller.current_absence
        
        {
          id: seller.id.to_s,
          name: seller.name,
          active: seller.active?,
          is_busy: seller.is_busy,
          is_absent: current_absence.present?,
          queue_order: seller.queue_order,
          current_absence: current_absence ? {
            id: current_absence.id.to_s,
            absence_type: current_absence.absence_type,
            start_date: current_absence.start_date,
            end_date: current_absence.end_date
          } : nil
        }
      end

      render json: { message: "Ordem atualizada com sucesso", sellers: sellers_data }
    rescue ActiveRecord::RecordNotFound => e
      render json: { error: "Registro não encontrado: #{e.message}" }, status: :not_found
    rescue ActiveRecord::RecordInvalid => e
      render json: { error: "Dados inválidos: #{e.message}" }, status: :unprocessable_entity
    rescue => e
      render json: { error: "Erro interno: #{e.message}" }, status: :internal_server_error
    end
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
      queue_order: seller.queue_order,
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

  # Calcula dias únicos com vendas do vendedor
  def calculate_days_with_sales(seller, start_date, end_date)
    seller.orders
          .joins(:order_items)
          .where('order_items.quantity > 0 AND order_items.unit_price > 0')
          .where('orders.sold_at >= ? AND orders.sold_at <= ?', start_date, end_date)
          .group('DATE(orders.sold_at)')
          .count
          .keys
          .count
  end

  # Calcula vendas líquidas considerando devoluções e trocas
  def calculate_net_sales(seller, start_date, end_date)
    # Vendas brutas
    gross_orders = seller.orders.includes(:order_items)
                        .where('sold_at >= ? AND sold_at <= ?', start_date, end_date)
    gross_sales = gross_orders.joins(:order_items)
                             .sum('order_items.quantity * order_items.unit_price')
    
    # Devoluções
    returns = Return.where(seller_id: seller.id)
                   .where('returns.processed_at >= ? AND returns.processed_at <= ?', start_date, end_date)
    total_returned = returns.sum(&:return_value)
    
    # Trocas
    exchanges = Exchange.where(seller_id: seller.id)
                       .where('processed_at >= ? AND processed_at <= ?', start_date, end_date)
    credit_exchanges = exchanges.where(is_credit: true).sum(:voucher_value)
    debit_exchanges = exchanges.where(is_credit: false).sum(:voucher_value)
    
    # Valor líquido = Vendas brutas - Devoluções - Trocas a crédito - Trocas a débito
    net_sales = gross_sales - total_returned - credit_exchanges - debit_exchanges
    
    {
      gross_sales: gross_sales,
      total_returned: total_returned,
      credit_exchanges: credit_exchanges,
      debit_exchanges: debit_exchanges,
      net_sales: net_sales
    }
  end
end
