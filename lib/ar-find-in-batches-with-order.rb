require "ar-find-in-batches-with-order/version"

module ActiveRecord
  module FindInBatchesWithOrder
    def find_in_batches_with_order(options = {})
      relation = self

      # we have to be explicit about the options to ensure proper ordering and retrieval

      direction = options.delete(:direction) || (arel.orders.first.try(:ascending?) ? :asc : nil) || (arel.orders.first.try(:descending?) ? :desc : nil) || :desc
      start = options.delete(:start)
      batch_size = options.delete(:batch_size) || 1000

      # try to deduct the property_key, but safer to specificy directly
      property_key = options.delete(:property_key) || arel.orders.first.try(:value).try(:name) || arel.orders.first.try(:split,' ').try(:first)
      sanitized_key = ActiveRecord::Base.connection.quote_column_name(property_key)
      relation = relation.limit(batch_size)

      # in strictmode, we return records with same values as the last record of the last batch
      strict_mode = options.delete(:strict_mode) || true


      records = start ? (direction == :desc ? relation.where("#{sanitized_key} <= ?", start).to_a : relation.where("#{sanitized_key} >= ?", start).to_a)  : relation.to_a

      while records.any?
        records_size = records.size

        yield records


        break if records_size < batch_size

        start = records.last.try(property_key)

        records = strict_mode ? (direction == :desc ? relation.where("#{sanitized_key} <= ?", start).to_a : relation.where("#{sanitized_key} >= ?", start).to_a) : (direction == :desc ? relation.where("#{sanitized_key} < ?", start).to_a : relation.where("#{sanitized_key} > ?", start).to_a)
      end
    end

    # note that in strict mode we might itereate perpetually if the overlap in values is too high in relation to the batch size
    def find_each_with_order(options = {})
      last_record = nil
      find_in_batches_with_order(options) do |records|

        records.each do |record|
          # we need to find the last record of the previous batch
          next if last_record and (record != last_record)
          if last_record
            last_record = nil
            next
          end
          yield record
        end
        last_record = records.last
      end
    end


  end

  class Relation
    include FindInBatchesWithOrder
  end
end
