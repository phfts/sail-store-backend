require_relative '../test_helper'

class OrderTest < ActiveSupport::TestCase
  
  def setup
    # Usar dados já existentes no banco
    @seller1 = Seller.first
    if Seller.count > 1
      @seller2 = Seller.second
    else
      @seller2 = @seller1
    end
    
    # Se não houver sellers, pular os testes
    skip "Nenhum seller encontrado no banco de dados" if @seller1.nil?
    
    @order_attributes = {
      sold_at: Date.current
    }
  end

  def teardown
    # Limpar apenas os dados de teste criados
    Order.where('external_id LIKE ?', 'TEST_%').destroy_all
  end

  test "should allow creating multiple orders with nil external_id" do
    # Criar 3 ordens com external_id em branco
    order1 = Order.new(@order_attributes.merge(seller: @seller1, external_id: nil))
    order2 = Order.new(@order_attributes.merge(seller: @seller1, external_id: nil))
    order3 = Order.new(@order_attributes.merge(seller: @seller1, external_id: nil))
    
    assert order1.save, "Order1 deveria ser salva com external_id nil"
    assert order2.save, "Order2 deveria ser salva com external_id nil"
    assert order3.save, "Order3 deveria ser salva com external_id nil"
    
    assert_nil order1.external_id
    assert_nil order2.external_id
    assert_nil order3.external_id
  end

  test "should allow creating order with new external_id" do
    # Criar uma ordem com external_id novo
    order = Order.new(@order_attributes.merge(seller: @seller1, external_id: "NEW_EXTERNAL_ID_123"))
    
    assert order.save, "Order deveria ser salva com external_id novo"
    assert_equal "NEW_EXTERNAL_ID_123", order.external_id
  end

  test "should not allow creating order with duplicate external_id in same store" do
    # Criar primeira ordem com external_id
    order1 = Order.create!(@order_attributes.merge(seller: @seller1, external_id: "DUPLICATE_ID_456"))
    
    # Tentar criar segunda ordem com mesmo external_id na mesma loja
    order2 = Order.new(@order_attributes.merge(seller: @seller1, external_id: "DUPLICATE_ID_456"))
    
    assert_not order2.save, "Order2 não deveria ser salva com external_id duplicado"
    assert_includes order2.errors[:external_id], "já existe um pedido com este external_id nesta loja"
  end

  test "should allow creating orders with same external_id in different stores" do
    # Criar primeira ordem na primeira loja
    order1 = Order.create!(
      seller: @seller1,
      external_id: "SAME_ID_789",
      sold_at: Date.current
    )
    
    # Criar segunda ordem na segunda loja com mesmo external_id
    order2 = Order.create!(
      seller: @seller2,
      external_id: "SAME_ID_789",
      sold_at: Date.current
    )
    
    assert_equal "SAME_ID_789", order1.external_id
    assert_equal "SAME_ID_789", order2.external_id
    assert_not_equal order1.seller_id, order2.seller_id
  end

  test "should validate external_id uniqueness only when present" do
    # Criar ordem com external_id
    order1 = Order.create!(@order_attributes.merge(seller: @seller1, external_id: "TEST_ID_999"))
    
    # Criar ordem com external_id nil (deveria ser permitido)
    order2 = Order.new(@order_attributes.merge(seller: @seller1, external_id: nil))
    
    assert order2.save, "Order com external_id nil deveria ser salva mesmo com outra ordem tendo external_id"
  end
end
