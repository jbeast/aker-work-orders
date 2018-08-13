require 'active_support/concern'

module LinkableToSets
  extend ActiveSupport::Concern

  included do
    def find_set(set_uuid)
      set_client.find(set_uuid).first
    end

    def find_with_materials(set_uuid)
      set_client.find_with_materials(set_uuid)
    end

    def fetch_materials(material_ids)
      all_results(material_client.where('_id' => { '$in' => material_ids }).result_set)
    end

    def fetch_containers_for_material_ids(material_ids)
      all_results(container_client.where('slots.material': { '$in': material_ids }).result_set)
    end

    private

    def set_client
      SetClient::Set
    end

    def material_client
      MatconClient::Material
    end

    def container_client
      MatconClient::Container
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

  class_methods do

    # Takes a list of attributes that are UUIDs from Sets the Set Service
    # and create getter and setter methods for each one
    #
    # Example:
    # link_to_set :original_set_uuid, :finished_set_uuid
    #
    # Creates instance methods original_set_uuid and finished_set_uuid that each
    # return an instance of SetClient::Set (or nil if :attribute? returns false)
    #
    # Creates setter instance methods original_set= and finished_set=
    # that set original_set_uuid and finished_set_uuid to their Set's uuid respectively
    #
    # Creates methods to return the size of the Sets i.e. original_set_size and finished_set_size
    #
    # Creates methods to return materials of a Set i.e. original_set_materials and finished_set_materials
    #
    # Creates methods to return an Array of the material_ids in a Set i.e. original_set_material_ids and
    # finished_set_material_ids
    def link_to_set(*attrs)
      attrs.each do |attribute|
        stripped_attr = attribute.to_s.sub(/_uuid/, '')

        # Name of the method to be created
        getter_method_name            = stripped_attr.to_sym
        setter_method_name            = "#{stripped_attr}=".to_sym
        size_method_name              = "#{stripped_attr}_size".to_sym
        set_materials_method_name     = "#{stripped_attr}_materials".to_sym
        set_material_ids_method_name  = "#{stripped_attr}_material_ids".to_sym
        full_materials_method_name    = "#{stripped_attr}_full_materials".to_sym
        set_containers_method_name    = "#{stripped_attr}_containers".to_sym

        # Name of the instance variable we memoize the output of the method
        instance_variable_name = "@#{stripped_attr}"

        # Name of the method to check if attribute is set
        existance_name = "#{attribute}?".to_sym

        # e.g. original_set_uuid --> original_set
        define_method getter_method_name do
          return nil unless send(existance_name)
          return instance_variable_get(instance_variable_name) unless instance_variable_get(instance_variable_name).nil?
          return instance_variable_set(instance_variable_name, find_set(send(attribute)))
        end

        # e.g. original_set_uuid --> original_set=
        define_method setter_method_name do |set|
          send("#{attribute}=", set&.uuid)
          return instance_variable_set(instance_variable_name, set)
        end

        # e.g. original_set_uuid --> original_set_size
        define_method size_method_name do
          send(getter_method_name) && send(getter_method_name).meta['size']
        end

        # e.g. original_set_uuid --> original_set_materials
        define_method set_materials_method_name do
          find_with_materials(send(attribute)).first.materials
        end

        # e.g. original_set_uuid --> original_set_material_ids
        define_method set_material_ids_method_name do
          send(set_materials_method_name).map(&:id)
        end

        # e.g. original_set_uuid --> original_set_full_materials
        define_method full_materials_method_name do
          fetch_materials(send(set_material_ids_method_name))
        end

        # e.g. original_set_uuid --> original_set_containers
        define_method set_containers_method_name do
          fetch_containers_for_material_ids(send(set_material_ids_method_name))
        end
      end
    end

  end

end