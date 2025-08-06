class OrderBulkService
  def initialize
    @errors = []
    @created_orders = []
    @created_order_items = []
    @skipped_orders = []
    @skipped_order_items = []
  end

  # Carrega pedidos em lote, evitando duplicatas
  def load_orders(orders_data)
    return { error: "Dados de pedidos são obrigatórios" } if orders_data.blank?

    # Agrupa por external_id para processar em lote
    external_ids = orders_data.map { |order| order[:external_id] }.compact.uniq
    
    # Busca pedidos existentes
    existing_orders = Order.where(external_id: external_ids).index_by(&:external_id)
    
    orders_data.each do |order_data|
      external_id = order_data[:external_id]
      
      if existing_orders[external_id]
        @skipped_orders << {
          external_id: external_id,
          reason: "Pedido já existe"
        }
        next
      end

      begin
        order = Order.new(order_data)
        if order.save
          @created_orders << order
        else
          @errors << {
            external_id: external_id,
            errors: order.errors.full_messages
          }
        end
      rescue => e
        @errors << {
          external_id: external_id,
          errors: [e.message],
          data_sent: order_data,
          error_class: e.class.name
        }
      end
    end

    build_response
  end

  # Carrega itens de pedido em lote, evitando duplicatas
  def load_order_items(order_items_data)
    return { error: "Dados de itens de pedido são obrigatórios" } if order_items_data.blank?

    # Agrupa por order_id e product_id para processar em lote
    order_product_pairs = order_items_data.map { |item| [item[:order_id], item[:product_id]] }
    
    # Busca itens existentes
    existing_items = OrderItem.where(
      order_id: order_items_data.map { |item| item[:order_id] },
      product_id: order_items_data.map { |item| item[:product_id] }
    ).index_by { |item| [item.order_id, item.product_id] }

    order_items_data.each do |item_data|
      order_id = item_data[:order_id]
      product_id = item_data[:product_id]
      
      if existing_items[[order_id, product_id]]
        @skipped_order_items << {
          order_id: order_id,
          product_id: product_id,
          reason: "Item já existe para este pedido e produto"
        }
        next
      end

      begin
        # Cria o order_item usando apenas os atributos permitidos
        order_item = OrderItem.new(
          order_id: item_data[:order_id],
          product_id: item_data[:product_id],
          store_id: item_data[:store_id],
          quantity: item_data[:quantity],
          unit_price: item_data[:unit_price]
        )
        if order_item.save
          @created_order_items << order_item
        else
          @errors << {
            order_id: order_id,
            product_id: product_id,
            errors: order_item.errors.full_messages
          }
        end
      rescue => e
        @errors << {
          order_id: order_id,
          product_id: product_id,
          errors: [e.message],
          data_sent: item_data,
          error_class: e.class.name
        }
      end
    end

    build_response
  end

  # Carrega pedidos e seus itens em uma única operação
  def load_orders_with_items(orders_with_items_data)
    return { error: "Dados de pedidos com itens são obrigatórios" } if orders_with_items_data.blank?

    Order.transaction do
      orders_with_items_data.each do |order_data|
        external_id = order_data[:external_id]
        items_data = order_data.delete(:order_items) || []

        # Verifica se o pedido já existe
        existing_order = Order.find_by(external_id: external_id)
        
        if existing_order
          @skipped_orders << {
            external_id: external_id,
            reason: "Pedido já existe"
          }
          next
        end

        begin
          # Log para debug
          Rails.logger.info "OrderBulkService: Processando order #{order_data[:external_id]}"
          Rails.logger.info "OrderBulkService: Dados recebidos: #{order_data.inspect}"
          
          # Cria o order usando apenas os atributos permitidos
          # Remove qualquer atributo não permitido
          permitted_attributes = {
            external_id: order_data[:external_id],
            seller_id: order_data[:seller_id],
            sold_at: order_data[:sold_at]
          }
          
          # Remove valores nil
          permitted_attributes = permitted_attributes.compact
          
          Rails.logger.info "OrderBulkService: Atributos permitidos: #{permitted_attributes.inspect}"
          
          order = Order.new(permitted_attributes)
          
          if order.save
            @created_orders << order
            
            # Processa os itens do pedido
            items_data.each do |item_data|
              item_data[:order_id] = order.id
              
              # Verifica se o item já existe
              existing_item = OrderItem.find_by(
                order_id: order.id,
                product_id: item_data[:product_id]
              )
              
              if existing_item
                @skipped_order_items << {
                  order_id: order.id,
                  product_id: item_data[:product_id],
                  reason: "Item já existe para este pedido e produto"
                }
                next
              end

              order_item = OrderItem.new(item_data)
              if order_item.save
                @created_order_items << order_item
              else
                @errors << {
                  external_id: external_id,
                  order_id: order.id,
                  product_id: item_data[:product_id],
                  errors: order_item.errors.full_messages
                }
              end
            end
          else
            @errors << {
              external_id: external_id,
              errors: order.errors.full_messages
            }
          end
        rescue => e
          @errors << {
            external_id: external_id,
            errors: [e.message]
          }
        end
      end
    end

    build_response
  end

  private

  def build_response
    {
      success: @errors.empty?,
      created_orders: @created_orders.as_json(
        include: { 
          seller: { only: [:id, :name, :external_id] },
          order_items: {
            include: { product: { only: [:id, :name, :external_id] } }
          }
        },
        methods: [:total]
      ),
      created_order_items: @created_order_items.as_json(
        include: { 
          order: { only: [:id, :external_id] },
          product: { only: [:id, :name, :external_id] }
        },
        methods: [:subtotal]
      ),
      skipped_orders: @skipped_orders,
      skipped_order_items: @skipped_order_items,
      errors: @errors,
      summary: {
        total_created_orders: @created_orders.count,
        total_created_order_items: @created_order_items.count,
        total_skipped_orders: @skipped_orders.count,
        total_skipped_order_items: @skipped_order_items.count,
        total_errors: @errors.count
      }
    }
  end
end 