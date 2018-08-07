# Splitter that finds all Containers for a Set, and yields the Materials in each Container
module WorkOrderSplitter
  class ByContainer < Splitter

    def splits
      work_order_containers.each do |container|
        yield container.material_ids & work_order_set_material_ids
      end
    end

  private

    def work_order_containers
      get_containers_for_material_ids(work_order_set_material_ids)
    end

    def work_order_set_material_ids
      @set_material_ids ||= work_order_set.materials.map(&:id)
    end

    def get_containers_for_material_ids(material_ids)
      all_results(MatconClient::Container.where(
        "slots.material": { "$in": material_ids }
      ).result_set).uniq
    end

    def work_order_set
      get_set_with_materials(work_order.set_uuid)
    end

    def get_set_with_materials(set_uuid)
      SetClient::Set.find_with_materials(set_uuid).first
    end

    def all_results(result_set)
      results = result_set.to_a
      while result_set.has_next? do
        result_set = result_set.next
        results += result_set.to_a
      end
      results
    end

  end
end