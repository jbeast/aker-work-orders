require 'active_support/concern'

module LinkableToContainers
  extend ActiveSupport::Concern

  included do
    def find_container(container)
      container_client.find(container)
    end

    private

    def container_client
      MatconClient::Container
    end

  end

  class_methods do

    def link_to_container(*attrs)
      attrs.each do |attribute|
        stripped_attr = attribute.to_s.sub(/_uuid/, '')

        # Name of the method to be created
        getter_method_name            = stripped_attr.to_sym
        setter_method_name            = "#{stripped_attr}=".to_sym

        # Name of the instance variable we memoize the output of the method
        instance_variable_name = "@#{stripped_attr}"

        # Name of the method to check if attribute is set
        existance_name = "#{attribute}?".to_sym

        # e.g. container_uuid --> container
        define_method getter_method_name do
          return nil unless send(existance_name)
          return instance_variable_get(instance_variable_name) unless instance_variable_get(instance_variable_name).nil?
          return instance_variable_set(instance_variable_name, find_container(send(attribute)))
        end

        # e.g. container_uuid --> container=
        define_method setter_method_name do |container|
          send("#{attribute}=", container&.uuid)
          return instance_variable_set(instance_variable_name, container)
        end

      end
    end

  end

end