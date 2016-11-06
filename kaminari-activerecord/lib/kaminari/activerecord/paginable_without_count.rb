# frozen_string_literal: true
module Kaminari
  module PaginableWithoutCount
    ORG_LOAD_METHOD = ActiveRecord::Relation.instance_method(:load)
    private_constant :ORG_LOAD_METHOD

    # if ORG_LOAD_METHOD.parameters.empty?
      def load # Rails 5.0.0.1 and earlier
        if loaded? || limit_value.nil?
          super
        else
          _records  = ORG_LOAD_METHOD.bind(limit(limit_value.succ)).call.to_a
          @has_next = !! _records.delete_at(limit_value.to_i)
          @records  = _records
          @records  = @records.freeze if ActiveRecord::VERSION::MAJOR == 5
          @loaded   = true

          self
        end
      end
    # else
    #   def load(&block) # Rails 5-0-stable (as of Nov 6, 2016) and edge
    #     if loaded? || limit_value.nil?
    #       super
    #     else
    #       _records  = ORG_LOAD_METHOD.bind(limit(limit_value.succ)).call(&block).to_a
    #       @has_next = !! _records.delete_at(limit_value.to_i)

    #       load_records(_records)
    #       self
    #     end
    #   end
    # end

    def last_page?
      !out_of_range? && !@has_next
    end

    def out_of_range?
      to_a.empty?
    end

    def total_pages
      raise "This scope is marked as a non-count paginate scope and can't be used in combination " \
            "with `#paginate' or `#page_entries_info'. Use `#paginate_without_count' instead."
    end

    def total_count
      raise "This scope is marked as a non-count paginate scope and can't be used in combination " \
            "with `#paginate' or `#page_entries_info'. Use `#paginate_without_count' instead."
    end
  end
end
