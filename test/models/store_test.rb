require "test_helper"

class StoreTest < ActiveSupport::TestCase
  test "should delete associated records when store is deleted" do
    store = stores(:one)
    seller = sellers(:one)
    shift = shifts(:one)
    
    # Verifica que os registros associados existem
    assert seller.present?
    assert shift.present?
    
    # Deleta a loja
    store.destroy
    
    # Verifica que os registros associados foram deletados
    assert_nil Seller.find_by(id: seller.id)
    assert_nil Shift.find_by(id: shift.id)
  end
end
