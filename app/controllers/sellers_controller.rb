class SellersController < ApplicationController
  before_action :set_seller, only: %i[ show update destroy ]
  before_action :require_admin!, only: %i[ create update destroy ]
  before_action :ensure_store_access, only: %i[ index by_store_slug show ]

  # GET /sellers
  def index
    # Forçar acesso através do slug da loja
    render json: { error: "Acesso negado. Use /stores/:slug/sellers para acessar vendedores de uma loja específica." }, status: :forbidden
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
      sellers = store.company.sellers.includes(:user, :store)
      
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
      render json: { errors: @seller.errors.full_messages }, status: :unprocessable_entity
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
      render json: { errors: @seller.errors.full_messages }, status: :unprocessable_entity
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

  # DELETE /sellers/1
  def destroy
    @seller.destroy
    render json: { message: 'Vendedor excluído com sucesso' }
  end

  private

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
