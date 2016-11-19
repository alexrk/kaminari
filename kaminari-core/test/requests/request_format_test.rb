# encoding: UTF-8
# frozen_string_literal: true
require 'test_helper'

class RenderingWithFormatOptionTest < ActionDispatch::IntegrationTest
  setup do
    User.create! :name => 'user1'
  end

  test "Make sure that kaminari doesn't affect the format" do
    visit '/users/index_text.text'

    assert_equal 200, page.status_code
    assert page.has_content? 'partial1'
    assert page.has_content? 'partial2'
  end
end
