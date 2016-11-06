# frozen_string_literal: true
require 'spec_helper'

describe Kaminari::PaginableWithoutCount, if: defined?(ActiveRecord) do
  before :all do
    26.times { User.create! }
  end

  after :all do
    User.delete_all
  end

  subject { @users }

  it 'does not make count queires after calling #each' do
    @scope = User.page(1).without_count
    @scope.each

    assert_no_queries { @scope.should_not be_last_page }
    assert_no_queries { @scope.should_not be_out_of_range }
  end

  it 'does not make count queires after calling #last_page? or #out_of_range?' do
    @scope = User.page(1).without_count
    @scope.should_not be_last_page
    @scope.should_not be_out_of_range

    assert_no_queries { @scope.each }
  end

  context 'when on the first page' do
    before { @users = User.page(1).without_count.load }

    its(:size)          { should == 25 }
    its('each.size')    { should == 25 }
    its(:last_page?)    { should == false }
    its(:out_of_range?) { should == false }
  end

  context 'when on the first page showing 26 elements' do
    before { @users = User.page(1).per(26).without_count.load }

    its(:size)          { should == 26 }
    its('each.size')    { should == 26 }
    its(:last_page?)    { should == true }
    its(:out_of_range?) { should == false }
  end

  context 'when on the last page' do
    before { @users = User.page(2).without_count.load }

    its(:size)          { should == 1 }
    its('each.size')    { should == 1 }
    its(:last_page?)    { should == true }
    its(:out_of_range?) { should == false }
  end

  context 'when out of range' do
    before { @users = User.page(3).without_count.load }

    its(:size)          { should == 0 }
    its('each.size')    { should == 0 }
    its(:last_page?)    { should == false }
    its(:out_of_range?) { should == true }
  end

  def assert_no_queries
    subscriber = ActiveSupport::Notifications.subscribe 'sql.active_record' do
      raise 'A SQL query is being made to the db:'
    end
    yield
  ensure
    ActiveSupport::Notifications.unsubscribe subscriber
  end
end
