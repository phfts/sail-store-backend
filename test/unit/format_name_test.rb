require 'test_helper'

class FormatNameTest < ActiveSupport::TestCase
  
  def setup
    @controller = BetaController.new
  end

  test "should return empty string for nil input" do
    result = @controller.send(:format_name, nil)
    assert_equal "", result
  end

  test "should return empty string for empty string input" do
    result = @controller.send(:format_name, "")
    assert_equal "", result
  end

  test "should return empty string for whitespace only input" do
    result = @controller.send(:format_name, "   ")
    assert_equal "", result
  end

  test "should return empty string for tabs and newlines only" do
    result = @controller.send(:format_name, "\t\n  \r")
    assert_equal "", result
  end

  test "should capitalize single lowercase word" do
    result = @controller.send(:format_name, "maria")
    assert_equal "Maria", result
  end

  test "should capitalize single uppercase word" do
    result = @controller.send(:format_name, "MARIA")
    assert_equal "Maria", result
  end

  test "should capitalize mixed case word" do
    result = @controller.send(:format_name, "mArIa")
    assert_equal "Maria", result
  end

  test "should handle multiple words (only first letter capitalized)" do
    result = @controller.send(:format_name, "MARIA LIGIA DA SILVA")
    assert_equal "Maria ligia da silva", result
  end

  test "should handle name with leading/trailing spaces" do
    result = @controller.send(:format_name, "  ELAINE  ")
    assert_equal "Elaine", result
  end

  test "should handle name with mixed spaces" do
    result = @controller.send(:format_name, "  ELAINE DIOGO PAULO  ")
    assert_equal "Elaine diogo paulo", result
  end

  test "should handle single character" do
    result = @controller.send(:format_name, "A")
    assert_equal "A", result
  end

  test "should handle single character lowercase" do
    result = @controller.send(:format_name, "a")
    assert_equal "A", result
  end

  test "should handle names with special characters" do
    result = @controller.send(:format_name, "JOSÉ-MARIA")
    assert_equal "José-maria", result
  end

  test "should handle names with accents" do
    result = @controller.send(:format_name, "JOÃO ANDRÉ")
    assert_equal "João andré", result
  end

  test "should handle numeric input as string" do
    result = @controller.send(:format_name, 123)
    assert_equal "123", result
  end

  test "should handle zero as input" do
    result = @controller.send(:format_name, 0)
    assert_equal "0", result
  end

  test "should handle false as input" do
    result = @controller.send(:format_name, false)
    assert_equal "", result
  end
end

