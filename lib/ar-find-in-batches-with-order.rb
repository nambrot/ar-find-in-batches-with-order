require "ar-find-in-batches-with-order/version"

module ActiveRecord
  module FindInBatchesWithOrder
    def as_batches(args={},&blk)
      batch_size=args[:batch_size] || 1000
      offset=arel.offset || 0
      limit=arel.limit 
      if limit && (limit < batch_size) then batch_size = limit end
      records = self.offset(offset).limit(batch_size).all
      while records.any?
        offset += records.size
        records.each { |r| yield r }
        if limit then
          limit -= records.size 
          if (limit < batch_size) then batch_size = limit end
          if limit.zero? then
            return
          end
        end
        records = self.offset(offset).limit(batch_size).all      
      end
    end
  end
  class Relation
    include FindInBatchesWithOrder
  end
end