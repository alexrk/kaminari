# frozen_string_literal: true
require 'kaminari/helpers/paginator'

module Kaminari
  module Helpers
    class PaginatorWithoutCount < Paginator
      def initialize(template, current_page: nil, per_page: nil, last: nil, out_of_range: nil, **options) #:nodoc:
        super(template, options.reverse_merge(remote: false))

        @window_options = {}.freeze
        @options[:current_page] = CurrentPage.new(current_page, last, out_of_range)
      end

      # Always render given block as a view template
      def render(&block)
        instance_eval(&block)
        @output_buffer
      end

      %w[
        page_tag
        first_page_tag
        last_page_tag
        gap_tag
        each_page
        each_relevant_page
        relevant_pages
      ].each {|tag| undef :"#{tag}" }

      class CurrentPage < SimpleDelegator #:nodoc:
        def initialize(page_number, last, out_of_range) #:nodoc:
          super(page_number)
          @last, @out_of_range = last, out_of_range
        end

        attr :last, :out_of_range
        alias last? last
        alias out_of_range? out_of_range

        def first?
          __getobj__ == 1
        end
      end

      private_constant :CurrentPage
    end
  end
end
