class WorkOrder < ApplicationRecord
  belongs_to :product, optional: true

  def self.ACTIVE
    'active'
  end

  scope :active, -> { where(status: WorkOrder.ACTIVE) }
  scope :pending, -> { where.not(status: WorkOrder.ACTIVE) }

  def active?
    status == WorkOrder.ACTIVE
  end

  def proposal
  	return nil unless proposal_id
    return @proposal if @proposal&.id==proposal_id
	  @proposal = StudyClient::Node.find(proposal_id).first
  end

  def original_set
    return nil unless original_set_uuid
    return @original_set if @original_set&.uuid==original_set_uuid
    @original_set = SetClient::Set.find(original_set_uuid).first
  end

  def original_set=(orig_set)
    self.original_set_uuid = orig_set&.uuid
    @original_set = orig_set
  end

  def set
    return nil unless set_uuid
    return @set if @set&.uuid==set_uuid
    @set = SetClient::Set.find(set_uuid).first
  end

  def set=(set)
    self.set_uuid = set&.uuid
    @set = set
  end

  # Create a locked set from this work order's original set.
  def create_locked_set
    self.set = original_set.create_locked_clone("Work order #{id}")
    save!
  end

end
