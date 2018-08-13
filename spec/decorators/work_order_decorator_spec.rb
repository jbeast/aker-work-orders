# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WorkOrderDecorator do

  let(:work_order) { create(:work_order) }
  let(:decorated_work_order) { work_order.decorate }
  let(:set) { double("SetClient::Set", uuid: SecureRandom.uuid) }
  let(:locked_set) { double("SetClient::Set", uuid: SecureRandom.uuid, locked: true) }

  describe 'delegation' do

    it 'delegates to the WorkOrder' do
      expect(decorated_work_order.status).to eql(work_order.status)
      expect(decorated_work_order.created_at).to eql(work_order.created_at)
      expect(decorated_work_order.updated_at).to eql(work_order.updated_at)
      expect(decorated_work_order.total_cost).to eql(work_order.total_cost)
      expect(decorated_work_order.order_index).to eql(work_order.order_index)
      expect(decorated_work_order.dispatch_date).to eql(work_order.dispatch_date)
    end

  end

  describe '#set' do
    context 'when set_uuid? is false' do
      it 'is nil' do
        expect(decorated_work_order.set).to be_nil
      end
    end

    context 'when set_uuid? is true' do
      let(:work_order) { build(:work_order, set_uuid: SecureRandom.uuid) }

      before :each do
        stub_request(:get, "http://external-server:3000/api/v1/sets/#{work_order.set_uuid}")
          .to_return(status: 200, body: file_fixture("set.json"), headers: { 'Content-Type': 'application/vnd.api+json' })
      end

      it 'returns a SetClient::Set' do
        expect(decorated_work_order.set).to be_instance_of(SetClient::Set)
      end
    end

  end

  describe '#set=' do

    before do
      decorated_work_order.set = set
    end

    it 'sets set_uuid to set.uuid' do
      expect(decorated_work_order.set_uuid).to eql(set.uuid)
    end

    it 'sets the @set instance variable' do
      expect(decorated_work_order.set).to eq(set)
    end

  end

  describe '#original_set' do
    context 'when original_set_uuid? is false' do
      it 'is nil' do
        expect(decorated_work_order.original_set).to be_nil
      end
    end

    context 'when original_set_uuid? is true' do
      let(:work_order) { build(:work_order, original_set_uuid: SecureRandom.uuid) }

      before :each do
        stub_request(:get, "http://external-server:3000/api/v1/sets/#{work_order.original_set_uuid}")
          .to_return(status: 200, body: file_fixture("set.json"), headers: { 'Content-Type': 'application/vnd.api+json' })
      end

      it 'returns a SetClient::Set' do
        expect(decorated_work_order.original_set).to be_instance_of(SetClient::Set)
      end
    end
  end

  describe '#original_set=' do

    before do
      decorated_work_order.original_set = set
    end

    it 'sets original_set_uuid to original_set.uuid' do
      expect(decorated_work_order.original_set_uuid).to eql(set.uuid)
    end

    it 'sets the @original_set instance variable' do
      expect(decorated_work_order.original_set).to eq(set)
    end

  end

  describe '#finished_set' do
    context 'when finished_set_uuid? is false' do
      it 'is nil' do
        expect(decorated_work_order.finished_set).to be_nil
      end
    end

    context 'when finished_set_uuid? is true' do
      let(:work_order) { build(:work_order, finished_set_uuid: SecureRandom.uuid) }

      before :each do
        stub_request(:get, "http://external-server:3000/api/v1/sets/#{work_order.finished_set_uuid}")
          .to_return(status: 200, body: file_fixture("set.json"), headers: { 'Content-Type': 'application/vnd.api+json' })
      end

      it 'returns a SetClient::Set' do
        expect(decorated_work_order.finished_set).to be_instance_of(SetClient::Set)
      end
    end
  end

  describe '#finished_set=' do

    before do
      decorated_work_order.finished_set = set
    end

    it 'sets finished_set_uuid to finished_set.uuid' do
      expect(decorated_work_order.finished_set_uuid).to eql(set.uuid)
    end

    it 'sets the @finished_set instance variable' do
      expect(decorated_work_order.finished_set).to eq(set)
    end

  end

  describe '#set_size' do

    context 'when set has been set :p' do

      let(:set) { double("SetClient::Set", uuid: SecureRandom.uuid, meta: { 'size' => 96 }) }

      before :each do
        decorated_work_order.set = set
      end

      it 'returns the number of samples in #set' do
        expect(decorated_work_order.set_size).to eql(96)
      end

    end

    context 'when set is not set' do
      it 'returns nil' do
        expect(decorated_work_order.set_size).to be_nil
      end
    end

  end

  describe '#set_materials' do

    before do
      stub_request(:get, "http://external-server:3000/api/v1/sets/#{set.uuid}?include=materials")
        .to_return(status: 200, body: file_fixture("set_with_materials.json"), headers: { 'Content-Type': 'application/vnd.api+json'})

      decorated_work_order.set = set
    end

    it 'returns the materials in #set' do
      expect(decorated_work_order.set_materials).to all be_instance_of SetClient::Material
    end

  end

  describe '#set_material_ids' do

    before do
      stub_request(:get, "http://external-server:3000/api/v1/sets/#{set.uuid}?include=materials")
        .to_return(status: 200, body: file_fixture("set_with_materials.json"), headers: { 'Content-Type': 'application/vnd.api+json'})

      decorated_work_order.set = set
    end

    it 'returns the material_ids in #set' do
      material_ids = decorated_work_order.set_material_ids
      expect(material_ids).to be_instance_of Array
      expect(material_ids).to include("01cb5442-f7f1-4247-813e-8e7693b0b17d", "030a06d1-0309-4fb0-8c7f-571d5c8dcebc", "056ee9c0-0a9d-4213-bb68-0aacbc53653b", "06816dc3-f68e-4491-9b24-36a00e79133e", "082828d2-9635-4b7d-ba4c-46bddcb6692c")
    end

  end

  describe '#set_full_materials' do

    before do
      stub_request(:get, "http://external-server:3000/api/v1/sets/#{set.uuid}?include=materials")
        .to_return(status: 200, body: file_fixture("set_with_materials.json"), headers: { 'Content-Type': 'application/vnd.api+json'})

      stub_request(:post, "http://external-server:5000/materials/search").
        with(
          body: "{\"where\":{\"_id\":{\"$in\":[\"01cb5442-f7f1-4247-813e-8e7693b0b17d\",\"030a06d1-0309-4fb0-8c7f-571d5c8dcebc\",\"056ee9c0-0a9d-4213-bb68-0aacbc53653b\",\"06816dc3-f68e-4491-9b24-36a00e79133e\",\"082828d2-9635-4b7d-ba4c-46bddcb6692c\"]}}}",
        )
        .to_return(status: 200, body: file_fixture("materials.json"), headers: { 'Content-Type': 'application/json' })

      stub_request(:get, "http://external-server:5000/materials/json_schema")
        .to_return(status: 200, body: file_fixture("material_schema.json"), headers: { 'Content-Type': 'application/json' })

      decorated_work_order.set = set
    end

    it 'returns the materials in #set from the Materials Service' do
      materials = decorated_work_order.set_full_materials
      expect(materials).to all be_instance_of MatconClient::Material
      expect(materials.map(&:id)).to include("01cb5442-f7f1-4247-813e-8e7693b0b17d", "030a06d1-0309-4fb0-8c7f-571d5c8dcebc", "056ee9c0-0a9d-4213-bb68-0aacbc53653b", "06816dc3-f68e-4491-9b24-36a00e79133e", "082828d2-9635-4b7d-ba4c-46bddcb6692c")
    end

  end

  describe '#set_containers' do

    before do
      stub_request(:get, "http://external-server:3000/api/v1/sets/#{set.uuid}?include=materials")
        .to_return(status: 200, body: file_fixture("set_with_materials.json"), headers: { 'Content-Type': 'application/vnd.api+json'})

      stub_request(:post, "http://external-server:5000/containers/search")
        .with(
          body: "{\"where\":{\"slots.material\":{\"$in\":[\"01cb5442-f7f1-4247-813e-8e7693b0b17d\",\"030a06d1-0309-4fb0-8c7f-571d5c8dcebc\",\"056ee9c0-0a9d-4213-bb68-0aacbc53653b\",\"06816dc3-f68e-4491-9b24-36a00e79133e\",\"082828d2-9635-4b7d-ba4c-46bddcb6692c\"]}}}",
        )
        .to_return(status: 200, body: file_fixture("containers.json"), headers: { 'Content-Type' => 'application/json' })

      stub_request(:get, "http://external-server:5000/containers/json_schema")
        .to_return(status: 200, body: file_fixture("container_schema.json").read, headers: { 'Content-Type' => 'application/vnd.api+json' })

      decorated_work_order.set = set
    end

    it 'returns the containers for materials in #set from the Materials Service' do
      containers = decorated_work_order.set_containers
      expect(containers).to all be_instance_of MatconClient::Container
    end
  end

  describe '#finalise_set' do

    let(:set) { double("SetClient::Set", uuid: SecureRandom.uuid, locked: false, name: 'Work Order Set') }

    context 'when the order already has a locked input set' do

      before :each do
        decorated_work_order.set = locked_set
      end

      it 'should return false' do
        expect(decorated_work_order.finalise_set).to be false
      end
    end

    context 'when the order doesn\'t have a set or original set' do

      it 'raises an error' do
        expect { decorated_work_order.finalise_set }.to raise_exception "No set selected for Work Order"
      end

    end

    context 'when the order has an unlocked input set' do

      before :each do
        decorated_work_order.set = set
        expect(decorated_work_order.set).to receive(:update_attributes).with(locked: true).and_return(true)
      end

      it 'returns true' do
        expect(decorated_work_order.finalise_set).to be true
      end

    end

    context 'when the input set fails to be locked' do

      before :each do
        decorated_work_order.set = set
        expect(decorated_work_order.set).to receive(:update_attributes).with(locked: true).and_return(false)
      end

      it 'raises an exception' do
        expect { decorated_work_order.finalise_set }.to raise_exception "Failed to lock set #{set.name}"
      end
    end

    context 'when the order has a locked original set' do

      before :each do
        decorated_work_order.original_set = locked_set
      end

      it 'sets the input set to the original set' do
        expect(decorated_work_order.finalise_set).to be false
        expect(decorated_work_order.set_uuid).to eq(locked_set.uuid)
      end
    end

    context 'when the order has an unlocked original set' do

      before :each do
        decorated_work_order.original_set = set
        expect(decorated_work_order.original_set).to receive(:create_locked_clone)
          .with(decorated_work_order.name).and_return(locked_set)
      end

      it 'creates a locked clone of the original set' do
        expect(decorated_work_order.finalise_set).to be true
        expect(decorated_work_order.set_uuid).to eq(locked_set.uuid)
      end
    end

  end

  describe '#create_editable_set' do

    context 'when the work order already has an input set' do
      let(:work_order) { create(:work_order, set_uuid: SecureRandom.uuid) }

      it 'raises an exception' do
        expect { decorated_work_order.create_editable_set }.to raise_exception "Work order already has input set"
      end
    end

    context 'when the work order has no original set' do
      it 'raises an exception' do
        expect { decorated_work_order.create_editable_set }.to raise_exception "Work order has no original set"
      end
    end

    context 'when the new set is created' do

      before do
        decorated_work_order.original_set = set
        allow(decorated_work_order.original_set).to receive(:create_unlocked_clone).and_return(locked_set)
      end

      it 'returns the new set' do
        expect(decorated_work_order.create_editable_set).to eq(locked_set)
        expect(decorated_work_order.original_set).to have_received(:create_unlocked_clone).with(work_order.name)
      end
    end
  end

  describe '#jobs' do
    let(:work_order) { build(:work_order, jobs: build_list(:job, 3))}

    it 'returns a collection of Jobs' do
      expect(decorated_work_order.jobs.length).to eql(3)
      expect(decorated_work_order.jobs).to all be_instance_of(Job)
    end
  end

  describe '#work_plan' do
    it 'returns a WorkPlan' do
      expect(decorated_work_order.work_plan).to be_instance_of WorkPlan
    end
  end

end