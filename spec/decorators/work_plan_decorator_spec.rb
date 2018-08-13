# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WorkPlanDecorator do

  let(:work_plan) { create(:work_plan) }
  let(:decorated_work_plan) { work_plan.decorate }
  let(:set) { double("SetClient::Set", uuid: SecureRandom.uuid) }

  describe 'delegation' do

    it 'delegates to the WorkPlan' do
      expect(decorated_work_plan.created_at).to eql(work_plan.created_at)
      expect(decorated_work_plan.updated_at).to eql(work_plan.updated_at)
      expect(decorated_work_plan.comment).to eql(work_plan.comment)
      expect(decorated_work_plan.owner_email).to eql(work_plan.owner_email)
      expect(decorated_work_plan.data_release_strategy_id).to eql(work_plan.data_release_strategy_id)
    end

  end

  describe '#original_set' do
    context 'when original_set_uuid? is false' do
      it 'is nil' do
        expect(decorated_work_plan.original_set).to be_nil
      end
    end

    context 'when original_set_uuid? is true' do
      let(:work_plan) { build(:work_plan, original_set_uuid: SecureRandom.uuid) }

      before :each do
        stub_request(:get, "http://external-server:3000/api/v1/sets/#{work_plan.original_set_uuid}")
          .to_return(status: 200, body: file_fixture("set.json"), headers: { 'Content-Type': 'application/vnd.api+json' })
      end

      it 'returns a SetClient::Set' do
        expect(decorated_work_plan.original_set).to be_instance_of(SetClient::Set)
      end
    end
  end

  describe '#original_set=' do

    before do
      decorated_work_plan.original_set = set
    end

    it 'sets original_set_uuid to set.uuid' do
      expect(decorated_work_plan.original_set_uuid).to eql(set.uuid)
    end

    it 'sets the @original_set instance variable' do
      expect(decorated_work_plan.original_set).to eq(set)
    end

  end

  describe '#original_set_size' do

    context 'when original_set has been set' do

      let(:set) { double("SetClient::Set", uuid: SecureRandom.uuid, meta: { 'size' => 96 }) }

      before :each do
        decorated_work_plan.original_set = set
      end

      it 'returns the number of samples in #original_set' do
        expect(decorated_work_plan.original_set_size).to eql(96)
      end

    end

    context 'when original_set is not set' do
      it 'returns nil' do
        expect(decorated_work_plan.original_set_size).to be_nil
      end
    end

  end

  describe '#project' do
    context 'when project_id? is false' do
      it 'is nil' do
        expect(decorated_work_plan.project).to be_nil
      end
    end

    context 'when project_id? is true' do
      let(:work_plan) { build(:work_plan, project_id: 999) }

      before :each do
        stub_request(:get, "http://external-server:3300/api/v1/nodes/999")
          .to_return(status: 200, body: file_fixture('project.json'), headers: { 'Content-Type': 'application/vnd.api+json'})
      end

      it 'returns a StudyClient::Node' do
        expect(decorated_work_plan.project).to be_instance_of(StudyClient::Node)
      end
    end

  end

  describe '#work_orders' do
    let(:work_plan) { build(:work_plan, work_orders: build_list(:work_order, 3))}

    it 'returns a collection of WorkOrders' do
      expect(decorated_work_plan.work_orders.length).to eql(3)
      expect(decorated_work_plan.work_orders).to all be_instance_of(WorkOrder)
    end

  end
end