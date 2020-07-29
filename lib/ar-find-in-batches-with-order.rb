require "ar-find-in-batches-with-order/version"

module ActiveRecord
  module FindInBatchesWithOrder
    def find_in_batches_with_order(options = {})
      relation = self

      # we have to be explicit about the options to ensure proper ordering and retrieval

      direction = options.delete(:direction) || (arel.orders.first.try(:ascending?) ? :asc : nil) || (arel.orders.first.try(:descending?) ? :desc : nil) || :desc
      start = options.delete(:start)
      batch_size = options.delete(:batch_size) || 1000
      with_start_ids = []

      # try to deduct the property_key, but safer to specificy directly
      property_key = options.delete(:property_key) || arel.orders.first.try(:value).try(:name) || arel.orders.first.try(:split,' ').try(:first)
      tbl = arel.orders.first.try(:value).try(:relation).try(:name) || connection.quote_table_name(options.delete(:property_table_name) || table.name)
      sanitized_key = "#{tbl}.#{connection.quote_column_name(property_key)}"
      relation = relation.limit(batch_size)

      records = start ? (direction == :desc ? relation.where("#{sanitized_key} <= ?", start).to_a : relation.where("#{sanitized_key} >= ?", start).to_a)  : relation.to_a

      while records.any?
        records_size = records.size

        yield records

        break if records_size < batch_size

        next_start = records.last.try(property_key)
        with_start_ids.clear if start != next_start
        start = next_start

        records.each do |record|
          if record.try(property_key) == start
            with_start_ids << record.id
          end
        end

        without_dups = relation.where.not(relation.klass.primary_key => with_start_ids)
        records = (direction == :desc ? without_dups.where("#{sanitized_key} <= ?", start).to_a : without_dups.where("#{sanitized_key} >= ?", start).to_a)
      end
    end

    def find_each_with_order(options = {})
      find_in_batches_with_order(options) do |records|

        records.each do |record|
          yield record
        end
      end
    end


  end

  class Relation
    include FindInBatchesWithOrder
  end
end
