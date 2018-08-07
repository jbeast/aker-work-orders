# Little abstract class for splitting Work Orders into Jobs
class WorkOrderSplitter

  def initialize(options)
    @work_order = options.fetch(:work_order)
  end


  def split
    splits do |material_ids|
      # Create Set
    end

    return jobs
  end

private

  # Expects method to yield a list of material ids
  def splits
    raise NotImplementedError
  end

  def rollback
    # Delete any created Sets
  end

end