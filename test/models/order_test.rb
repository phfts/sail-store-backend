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
    
    @store1 = @seller1.store
    @store2 = @seller2.store
    
    @order_attributes = {
      sold_at: Date.current,
      store: @store1
    }
  end

  def teardown
    # Limpar apenas os dados de teste criados
    Order.where('external_id LIKE ?', 'TEST_%').destroy_all
  end

  test "should not allow creating orders with nil external_id" do
    # Tentar criar ordens com external_id em branco (agora não é permitido)
    order1 = Order.new(@order_attributes.merge(seller: @seller1, store: @store1, external_id: nil))
    order2 = Order.new(@order_attributes.merge(seller: @seller1, store: @store1, external_id: ""))
    order3 = Order.new(@order_attributes.merge(seller: @seller1, store: @store1, external_id: ""))
    
    assert_not order1.save, "Order1 não deveria ser salva com external_id nil"
    assert_not order2.save, "Order2 não deveria ser salva com external_id vazio"
    assert_not order3.save, "Order3 não deveria ser salva com external_id vazio"
    
    assert_includes order1.errors[:external_id], "can't be blank"
    assert_includes order2.errors[:external_id], "can't be blank"
    assert_includes order3.errors[:external_id], "can't be blank"
  end

  test "should allow creating order with new external_id" do
    # Criar uma ordem com external_id novo
    order = Order.new(@order_attributes.merge(seller: @seller1, store: @store1, external_id: "NEW_EXTERNAL_ID_123"))
    
    assert order.save, "Order deveria ser salva com external_id novo"
    assert_equal "NEW_EXTERNAL_ID_123", order.external_id
  end

  test "should not allow creating order with duplicate external_id in same store" do
    # Criar primeira ordem com external_id
    order1 = Order.create!(@order_attributes.merge(seller: @seller1, store: @store1, external_id: "DUPLICATE_ID_456"))
    
    # Tentar criar segunda ordem com mesmo external_id na mesma loja
    order2 = Order.new(@order_attributes.merge(seller: @seller1, store: @store1, external_id: "DUPLICATE_ID_456"))
    
    assert_not order2.save, "Order2 não deveria ser salva com external_id duplicado"
    assert_includes order2.errors[:external_id], "já existe um pedido com este external_id nesta loja"
  end

  test "should allow creating orders with same external_id in different stores" do
    # Criar primeira ordem na primeira loja
    order1 = Order.create!(
      seller: @seller1,
      store: @store1,
      external_id: "SAME_ID_789",
      sold_at: Date.current
    )
    
    # Criar segunda ordem na segunda loja com mesmo external_id
    order2 = Order.create!(
      seller: @seller2,
      store: @store2,
      external_id: "SAME_ID_789",
      sold_at: Date.current
    )
    
    assert_equal "SAME_ID_789", order1.external_id
    assert_equal "SAME_ID_789", order2.external_id
    assert_not_equal order1.store_id, order2.store_id
  end

  test "should validate external_id uniqueness when present" do
    # Criar ordem com external_id
    order1 = Order.create!(@order_attributes.merge(seller: @seller1, store: @store1, external_id: "TEST_ID_999"))
    
    # Tentar criar ordem com external_id nil (agora não é permitido)
    order2 = Order.new(@order_attributes.merge(seller: @seller1, store: @store1, external_id: nil))
    
    assert_not order2.save, "Order com external_id nil não deveria ser salva"
    assert_includes order2.errors[:external_id], "can't be blank"
  end

  test "should validate store_id is required" do
    # Tentar criar ordem sem store_id
    order = Order.new(
      seller: @seller1,
      external_id: "TEST_NO_STORE",
      sold_at: Date.current
    )
    
    assert_not order.save, "Order não deveria ser salva sem store_id"
    assert_includes order.errors[:store], "must exist"
  end

  test "should validate external_id uniqueness per store correctly" do
    # Criar primeira ordem na primeira loja
    order1 = Order.create!(
      seller: @seller1,
      store: @store1,
      external_id: "STORE_UNIQUE_TEST",
      sold_at: Date.current
    )
    
    # Criar segunda ordem na segunda loja com mesmo external_id (deve funcionar)
    order2 = Order.create!(
      seller: @seller2,
      store: @store2,
      external_id: "STORE_UNIQUE_TEST",
      sold_at: Date.current
    )
    
    # Tentar criar terceira ordem na primeira loja com mesmo external_id (deve falhar)
    order3 = Order.new(
      seller: @seller1,
      store: @store1,
      external_id: "STORE_UNIQUE_TEST",
      sold_at: Date.current
    )
    
    assert_not order3.save, "Order3 não deveria ser salva com external_id duplicado na mesma loja"
    assert_includes order3.errors[:external_id], "já existe um pedido com este external_id nesta loja"
    
    # Verificar que as duas primeiras ordens foram criadas com sucesso
    assert order1.persisted?
    assert order2.persisted?
  end
end
