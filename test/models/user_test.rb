require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "should delete associated sellers when user is deleted" do
    user = users(:one)
    seller = sellers(:one)
    
    # Verifica que o seller existe
    assert seller.present?
    
    # Deleta o usuário
    user.destroy
    
    # Verifica que o seller foi deletado
    assert_nil Seller.find_by(id: seller.id)
  end
end
