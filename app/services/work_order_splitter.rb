# Little abstract class for splitting Work Orders into Jobs
module WorkOrderSplitter
  class Splitter

    attr_reader :work_order
    attr_accessor :sets

    def initialize(options)
      @work_order = options.fetch(:work_order)
      @sets       = []
    end

    def split
      begin
        ActiveRecord::Base.transaction do
          splits do |material_ids|
            job = work_order.jobs.create!

            set = SetClient::Set.create(
              name: "Job #{job.id} Input Set"
            )

            sets << set

            set.set_materials(material_ids)
            job.update_attributes!(input_set_uuid: set.id)
          end

          # Done last because you can't undo it
          lock_all_sets
        end
      rescue
        rollback
        return false
      end

      return true
    end

  protected

    # Expects template method to yield a list of material ids
    def splits
      raise NotImplementedError
    end

  private

    def lock_all_sets
      with_sets { |set| set.update_attributes(owner_id: work_order.work_plan.owner_email, locked: true) }
    end

    def rollback
      with_sets { |set| set.destroy }
    end

    def with_sets
      sets.each { |set| yield set }
    end

  end
end
