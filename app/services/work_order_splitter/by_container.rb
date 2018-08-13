# Splitter that finds all Containers for a Set, and yields the Materials in each Container
# that were also part of that Set
module WorkOrderSplitter
  class ByContainer < Splitter

    def splits(work_order)
      work_order.set_containers.uniq.each do |container|
        yield container.material_ids & work_order.set_material_ids
      end
    end

  end
end