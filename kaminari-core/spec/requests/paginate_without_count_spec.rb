# encoding: utf-8
# frozen_string_literal: true
require 'spec_helper'

feature 'Pagination without count' do
  background do
    1.upto(100) {|i| User.create! :name => "user#{'%03d' % i}" }
  end

  scenario 'navigating by pagination links' do
    visit '/paginate_without_count'

    within 'nav.pagination' do
      page.should_not have_content '‹ Prev'

      within 'span.next' do
        click_link 'Next ›'
      end
    end

    within 'nav.pagination' do
      page.should have_content '‹ Prev'
      page.should have_content 'Next ›'
    end

    visit '/paginate_without_count?page=4'

    within 'nav.pagination' do
      page.should_not have_content 'Next ›'

      within 'span.prev' do
        click_link '‹ Prev'
      end
    end
  end
end
