require 'test_helper'

class OrderBulkServiceTest < ActiveSupport::TestCase
  def setup
    @service = OrderBulkService.new
    @seller = sellers(:one)
    @product = products(:one)
    @store = stores(:one)
  end

  test "should load orders without duplicates" do
    # Create an existing order
    existing_order = Order.create!(
      external_id: "existing_order",
      seller: @seller,
      sold_at: Time.current
    )

    orders_data = [
      {
        external_id: "existing_order",
        seller_id: @seller.id,
        sold_at: Time.current
      },
      {
        external_id: "new_order",
        seller_id: @seller.id,
        sold_at: Time.current
      }
    ]

    result = @service.load_orders(orders_data)

    assert result[:success]
    assert_equal 1, result[:summary][:total_created_orders]
    assert_equal 1, result[:summary][:total_skipped_orders]
    assert_equal 0, result[:summary][:total_errors]
    
    # Check that only the new order was created
    assert_equal "new_order", result[:created_orders].first["external_id"]
    assert_equal "existing_order", result[:skipped_orders].first[:external_id]
  end

  test "should load order items without duplicates" do
    # Create an existing order and order item
    order = Order.create!(
      external_id: "test_order",
      seller: @seller,
      sold_at: Time.current
    )

    existing_item = OrderItem.create!(
      order: order,
      product: @product,
      store: @store,
      quantity: 1,
      unit_price: 10.0
    )

    order_items_data = [
      {
        order_id: order.id,
        product_id: @product.id,
        store_id: @store.id,
        quantity: 2,
        unit_price: 15.0
      },
      {
        order_id: order.id,
        product_id: products(:two).id,
        store_id: @store.id,
        quantity: 1,
        unit_price: 20.0
      }
    ]

    result = @service.load_order_items(order_items_data)

    assert result[:success]
    assert_equal 1, result[:summary][:total_created_order_items]
    assert_equal 1, result[:summary][:total_skipped_order_items]
    assert_equal 0, result[:summary][:total_errors]
  end

  test "should load orders with items in single transaction" do
    orders_with_items_data = [
      {
        external_id: "order_with_items",
        seller_id: @seller.id,
        sold_at: Time.current,
        order_items: [
          {
            product_id: @product.id,
            store_id: @store.id,
            quantity: 2,
            unit_price: 29.99
          },
          {
            product_id: products(:two).id,
            store_id: @store.id,
            quantity: 1,
            unit_price: 15.50
          }
        ]
      }
    ]

    result = @service.load_orders_with_items(orders_with_items_data)

    assert result[:success]
    assert_equal 1, result[:summary][:total_created_orders]
    assert_equal 2, result[:summary][:total_created_order_items]
    assert_equal 0, result[:summary][:total_errors]

    # Verify the order was created
    created_order = result[:created_orders].first
    assert_equal "order_with_items", created_order["external_id"]
    assert_equal 2, created_order["order_items"].length
  end

  test "should handle validation errors gracefully" do
    orders_data = [
      {
        external_id: "", # Invalid - empty external_id
        seller_id: @seller.id,
        sold_at: Time.current
      }
    ]

    result = @service.load_orders(orders_data)

    refute result[:success]
    assert_equal 0, result[:summary][:total_created_orders]
    assert_equal 1, result[:summary][:total_errors]
    assert_includes result[:errors].first[:errors], "External can't be blank"
  end

  test "should return error for empty data" do
    result = @service.load_orders([])
    assert_equal "Dados de pedidos são obrigatórios", result[:error]

    result = @service.load_order_items([])
    assert_equal "Dados de itens de pedido são obrigatórios", result[:error]

    result = @service.load_orders_with_items([])
    assert_equal "Dados de pedidos com itens são obrigatórios", result[:error]
  end
end 