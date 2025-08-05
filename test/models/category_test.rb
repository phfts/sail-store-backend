require "test_helper"

class CategoryTest < ActiveSupport::TestCase
  test "should delete associated products when category is deleted" do
    category = categories(:one)
    product = products(:one)
    
    # Verifica que o produto existe
    assert product.present?
    
    # Deleta a categoria
    category.destroy
    
    # Verifica que o produto foi deletado
    assert_nil Product.find_by(id: product.id)
  end
end
