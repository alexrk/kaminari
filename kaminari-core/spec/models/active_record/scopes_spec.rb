# frozen_string_literal: true
require 'spec_helper'

if defined? ActiveRecord
  describe Kaminari::ActiveRecordModelExtension do
    before do
      Kaminari.configure do |config|
        config.page_method_name = :per_page_kaminari
      end
    end

    subject { Class.new ActiveRecord::Base }
    it { should respond_to(:per_page_kaminari) }
    it { should_not respond_to(:page) }

    after do
      Kaminari.configure do |config|
        config.page_method_name = :page
      end
    end
  end

  describe Kaminari::ActiveRecordExtension do
    shared_examples_for 'the first page' do
      it { should have(25).users }
      its('first.name') { should == 'user001' }
    end

    shared_examples_for 'blank page' do
      it { should have(0).users }
    end

    before :all do
      [User, GemDefinedModel, Device].each do |m|
        1.upto(100) {|i| m.create! :name => "user#{'%03d' % i}", :age => (i / 10)}
      end
    end
    after :all do
      [User, GemDefinedModel, Device].each(&:delete_all)
    end

    [User, Admin, GemDefinedModel, Device].each do |model_class|
      context "for #{model_class}" do
        describe '#page' do
          context 'page 1' do
            subject { model_class.page 1 }
            it_should_behave_like 'the first page'
          end

          context 'page 2' do
            subject { model_class.page 2 }
            it { should have(25).users }
            its('first.name') { should == 'user026' }
          end

          context 'page without an argument' do
            subject { model_class.page }
            it_should_behave_like 'the first page'
          end

          context 'page < 1' do
            subject { model_class.page 0 }
            it_should_behave_like 'the first page'
          end

          context 'page > max page' do
            subject { model_class.page 5 }
            it_should_behave_like 'blank page'
          end

          describe 'ensure #order_values is preserved' do
            subject { model_class.order('id').page 1 }
            its('order_values.uniq') { should == ['id'] }
          end
        end

        describe '#per' do
          context 'page 1 per 5' do
            subject { model_class.page(1).per(5) }
            it { should have(5).users }
            its('first.name') { should == 'user001' }

            context 'with max_per_page < 5' do
              before { model_class.max_paginates_per 4 }
              it { should have(4).users }
              after { model_class.max_paginates_per nil }
            end
          end

          context "page 1 per nil (using default)" do
            subject { model_class.page(1).per(nil) }
            it { should have(model_class.default_per_page).users }

            context 'with max_per_page < default_per_page' do
              around do |example|
                begin
                  model_class.max_paginates_per(10)
                  example.run
                ensure
                  model_class.max_paginates_per(nil)
                end
              end

              it { should have(10).users }
            end
          end

          context "page 1 per 0" do
            subject { model_class.page(1).per(0) }
            it { should have(0).users }
          end

          # I know it's a bit strange to have this here, but I couldn't find any better place for this case
          context 'when max_per_page is given via model class, and `per` is not actually called' do
            subject { model_class.page(1) }

            context 'with max_per_page > default_per_page' do
              around do |example|
                begin
                  model_class.max_paginates_per(200)
                  example.run
                ensure
                  model_class.max_paginates_per(nil)
                end
              end

              it { should have(25).users }
            end

            context 'with max_per_page < default_per_page' do
              around do |example|
                begin
                  model_class.max_paginates_per(5)
                  example.run
                ensure
                  model_class.max_paginates_per(nil)
                end
              end

              it { should have(5).users }
            end
          end
        end

        describe '#max_paginates_per' do
          around do |example|
            begin
              model_class.max_paginates_per(10)
              example.run
            ensure
              model_class.max_paginates_per(nil)
            end
          end

          context 'calling max_paginates_per() after per()' do
            context 'when #max_paginates_per is greater than #per' do
              subject { model_class.page(1).per(15).max_paginates_per(20) }
              it { should have(15).users }
            end

            context 'when #per is greater than #max_paginates_per' do
              subject { model_class.page(1).per(30).max_paginates_per(20) }
              it { should have(20).users }
            end

            context 'when nil is given to #per and #max_paginates_per is specified' do
              subject { model_class.page(1).per(nil).max_paginates_per(20) }
              it { should have(20).users }
            end
          end

          context 'calling max_paginates_per() before per()' do
            context 'when #max_paginates_per is greater than #per' do
              subject { model_class.page(1).max_paginates_per(20).per(15) }
              it { should have(15).users }
            end

            context 'when #per is greater than #max_paginates_per' do
              subject { model_class.page(1).max_paginates_per(20).per(30) }
              it { should have(20).users }
            end

            context 'when nil is given to #per and #max_paginates_per is specified' do
              subject { model_class.page(1).max_paginates_per(20).per(nil) }
              it { should have(20).users }
            end
          end

          context 'calling max_paginates_per() without per()' do
            context 'when #max_paginates_per is greater than the default per_page' do
              subject { model_class.page(1).max_paginates_per(20) }
              it { should have(20).users }
            end

            context 'when #max_paginates_per is less than the default per_page' do
              subject { model_class.page(1).max_paginates_per(30) }
              it { should have(25).users }
            end
          end
        end

        describe '#padding' do
          context 'page 1 per 5 padding 1' do
            subject { model_class.page(1).per(5).padding(1) }
            it { should have(5).users }
            its('first.name') { should == 'user002' }
          end

          context 'page 19 per 5 padding 5' do
            subject { model_class.page(19).per(5).padding(5) }
            its(:current_page) { should == 19 }
            its(:total_pages) { should == 19 }
          end
        end

        describe '#total_pages' do
          context 'per 25 (default)' do
            subject { model_class.page }
            its(:total_pages) { should == 4 }
          end

          context 'per 7' do
            subject { model_class.page(2).per(7) }
            its(:total_pages) { should == 15 }
          end

          context 'per 65536' do
            subject { model_class.page(50).per(65536) }
            its(:total_pages) { should == 1 }
          end

          context 'per 0' do
            subject { model_class.page(50).per(0) }
            it "raises Kaminari::ZeroPerPageOperation" do
              expect { subject.total_pages }.to raise_error(Kaminari::ZeroPerPageOperation)
            end
          end

          context 'per -1 (using default)' do
            subject { model_class.page(5).per(-1) }
            its(:total_pages) { should == 4 }
          end

          context 'per "String value that can not be converted into Number" (using default)' do
            subject { model_class.page(5).per('aho') }
            its(:total_pages) { should == 4 }
          end

          context 'with max_pages < total pages count from database' do
            before { model_class.max_pages_per 3 }
            subject { model_class.page }
            its(:total_pages) { should == 3 }
            after { model_class.max_pages_per nil }
          end

          context 'with max_pages > total pages count from database' do
            before { model_class.max_pages_per 11 }
            subject { model_class.page }
            its(:total_pages) { should == 4 }
            after { model_class.max_pages_per nil }
          end

          context 'with max_pages is nil' do
            before { model_class.max_pages_per nil }
            subject { model_class.page }
            its(:total_pages) { should == 4 }
          end

          context "with per(nil) using default" do
            subject { model_class.page.per(nil) }
            its(:total_pages) { should == 4 }
          end
        end

        describe '#current_page' do
          context 'any page, per 0' do
            subject { model_class.page.per(0) }
            it "raises Kaminari::ZeroPerPageOperation" do
              expect { subject.current_page }.to raise_error(Kaminari::ZeroPerPageOperation)
            end
          end

          context 'page 1' do
            subject { model_class.page }
            its(:current_page) { should == 1 }
          end

          context 'page 2' do
            subject { model_class.page(2).per 3 }
            its(:current_page) { should == 2 }
          end
        end

        describe '#next_page' do
          context 'page 1' do
            subject { model_class.page }
            its(:next_page) { should == 2 }
          end

          context 'page 5' do
            subject { model_class.page(5) }
            its(:next_page) { should be_nil }
          end
        end

        describe '#prev_page' do
          context 'page 1' do
            subject { model_class.page }
            its(:prev_page) { should be_nil }
          end

          context 'page 3' do
            subject { model_class.page(3) }
            its(:prev_page) { should == 2 }
          end

          context 'page 5' do
            subject { model_class.page(5) }
            its(:prev_page) { should be_nil }
          end
        end

        describe '#first_page?' do
          context 'on first page' do
            subject { model_class.page(1).per(10) }
            its(:first_page?) { should == true }
          end

          context 'not on first page' do
            subject { model_class.page(5).per(10) }
            its(:first_page?) { should == false }
          end
        end

        describe '#last_page?' do
          context 'on last page' do
            subject { model_class.page(10).per(10) }
            its(:last_page?) { should == true }
          end

          context 'within range' do
            subject { model_class.page(1).per(10) }
            its(:last_page?) { should == false }
          end

          context 'out of range' do
            subject { model_class.page(11).per(10) }
            its(:last_page?) { should == false }
          end
        end

        describe '#out_of_range?' do
          context 'on last page' do
            subject { model_class.page(10).per(10) }
            its(:out_of_range?) { should == false }
          end

          context 'within range' do
            subject { model_class.page(1).per(10) }
            its(:out_of_range?) { should == false }
          end

          context 'out of range' do
            subject { model_class.page(11).per(10) }
            its(:out_of_range?) { should == true }
          end
        end

        describe '#count' do
          context 'page 1' do
            subject { model_class.page }
            its(:count) { should == 25 }
          end

          context 'page 2' do
            subject { model_class.page 2 }
            its(:count) { should == 25 }
          end
        end

        context 'chained with .group' do
          subject { model_class.group('age').page(2).per 5 }
          # 0..10
          its(:total_count) { should == 11 }
          its(:total_pages) { should == 3 }
        end

        context 'activerecord descendants' do
          subject { ActiveRecord::Base.descendants }
          its(:length) { should_not == 0 }
        end
      end
    end
  end
end
