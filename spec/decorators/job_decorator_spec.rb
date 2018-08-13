# frozen_string_literal: true

require 'rails_helper'

RSpec.describe JobDecorator do

  let(:job) { create(:job) }
  let(:decorated_job) { job.decorate }
  let(:set) { double("SetClient::Set", uuid: SecureRandom.uuid) }
  let(:container) { double("MatconClient::Container", uuid: SecureRandom.uuid) }

  describe 'delegation' do

    it 'delegates to the Job' do
      expect(decorated_job.started).to eql(job.started)
      expect(decorated_job.completed).to eql(job.completed)
      expect(decorated_job.close_comment).to eql(job.close_comment)
    end

  end

  describe '#set' do
    context 'when set_uuid? is false' do
      it 'is nil' do
        expect(decorated_job.set).to be_nil
      end
    end

    context 'when set_uuid? is true' do
      let(:job) { build(:job, set_uuid: SecureRandom.uuid) }

      before :each do
        stub_request(:get, "http://external-server:3000/api/v1/sets/#{job.set_uuid}")
          .to_return(status: 200, body: file_fixture("set.json"), headers: { 'Content-Type': 'application/vnd.api+json' })
      end

      it 'returns a SetClient::Set' do
        expect(decorated_job.set).to be_instance_of(SetClient::Set)
      end
    end
  end

  describe '#set=' do

    before do
      decorated_job.set = set
    end

    it 'sets set_uuid to set.uuid' do
      expect(decorated_job.set_uuid).to eql(set.uuid)
    end

    it 'sets the @set instance variable' do
      expect(decorated_job.set).to eq(set)
    end

  end

  describe '#set_materials' do

    before do
      stub_request(:get, "http://external-server:3000/api/v1/sets/#{set.uuid}?include=materials")
        .to_return(status: 200, body: file_fixture("set_with_materials.json"), headers: { 'Content-Type': 'application/vnd.api+json'})

      decorated_job.set = set
    end

    it 'returns the materials in #set' do
      expect(decorated_job.set_materials).to all be_instance_of SetClient::Material
    end

  end

  describe '#input_set' do
    context 'when input_set_uuid? is false' do
      it 'is nil' do
        expect(decorated_job.input_set).to be_nil
      end
    end

    context 'when input_set_uuid? is true' do
      let(:job) { build(:job, input_set_uuid: SecureRandom.uuid) }

      before :each do
        stub_request(:get, "http://external-server:3000/api/v1/sets/#{job.input_set_uuid}")
          .to_return(status: 200, body: file_fixture("set.json"), headers: { 'Content-Type': 'application/vnd.api+json' })
      end

      it 'returns a SetClient::Set' do
        expect(decorated_job.input_set).to be_instance_of(SetClient::Set)
      end
    end
  end

  describe '#set=' do

    before do
      decorated_job.input_set = set
    end

    it 'sets input_set_uuid to set.uuid' do
      expect(decorated_job.input_set_uuid).to eql(set.uuid)
    end

    it 'sets the @input_set instance variable' do
      expect(decorated_job.input_set).to eq(set)
    end

  end

  describe '#set_materials' do

    before do
      stub_request(:get, "http://external-server:3000/api/v1/sets/#{set.uuid}?include=materials")
        .to_return(status: 200, body: file_fixture("set_with_materials.json"), headers: { 'Content-Type': 'application/vnd.api+json'})

      decorated_job.input_set = set
    end

    it 'returns the materials in #input_set' do
      expect(decorated_job.input_set_materials).to all be_instance_of SetClient::Material
    end

  end

  describe '#container' do

    let(:job) { build(:job, container_uuid: container.uuid) }

    before do
      stub_request(:get, "http://external-server:5000/containers/#{container.uuid}")
        .to_return(status: 200, body: file_fixture("container.json"), headers: { 'Content-Type': 'application/json' })

      stub_request(:get, "http://external-server:5000/containers/json_schema")
        .to_return(status: 200, body: file_fixture("container_schema.json").read, headers: { 'Content-Type' => 'application/json' })
    end

    it 'returns the Container' do
      expect(decorated_job.container).to be_instance_of MatconClient::Container
    end

  end

  describe '#container=' do

    before do
      decorated_job.container = container
    end

    it 'sets container_uuid to container.uuid' do
      expect(decorated_job.container_uuid).to eql(container.uuid)
    end

    it 'containers the @container instance variable' do
      expect(decorated_job.container).to eq(container)
    end

  end

  describe '#work_order' do
    it 'returns a DecoratedWorkOrder' do
      expect(decorated_job.work_order).to be_instance_of WorkOrder
    end
  end

end