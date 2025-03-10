# frozen_string_literal: true

require 'monitor'

# Repository that stores objects in memory
# Provides basic CRUD operations for domain objects
class InMemoryRepository
  def initialize
    @objects = Hash.new { |hash, key| hash[key] = {} }
    @monitor = Monitor.new # For thread safety
  end

  # Check if the repository is empty
  # @return [Boolean] true if the repository is empty, false otherwise
  def empty?
    @monitor.synchronize do
      @objects.values.all?(&:empty?)
    end
  end

  # Add an object to the repository
  # @param object [Object] The object to add
  # @return [Object] The added object
  # @raise [ArgumentError] If the object is nil or does not have an id
  def add(object)
    validate_object(object)

    @monitor.synchronize do
      @objects[object.class][object.id] = object
    end

    object
  end

  # Find an object by type and id
  # @param type [Class] The type of the object
  # @param id [Object] The id of the object
  # @return [Object, nil] The found object, or nil if not found
  # @raise [ArgumentError] If type is nil
  def find(type, id)
    validate_type(type)

    @monitor.synchronize do
      @objects[type][id]
    end
  end

  # Get all objects of a given type
  # @param type [Class] The type of the objects
  # @return [Array<Object>] Array of all objects of the given type
  # @raise [ArgumentError] If type is nil
  def all(type)
    validate_type(type)

    @monitor.synchronize do
      @objects[type].values
    end
  end

  # Remove an object from the repository
  # @param object [Object] The object to remove
  # @return [Object, nil] The removed object, or nil if not found
  # @raise [ArgumentError] If the object is nil
  def remove(object)
    raise ArgumentError, 'Object cannot be nil' if object.nil?

    @monitor.synchronize do
      @objects[object.class].delete(object.id)
    end
  end

  # Remove all objects from the repository
  def clear
    @monitor.synchronize do
      @objects.clear
    end
  end

  private

  # Validate that an object is not nil and has an id
  # @param object [Object] The object to validate
  # @raise [ArgumentError] If the object is nil or does not have an id
  def validate_object(object)
    if object.nil?
      raise ArgumentError, 'Object cannot be nil'
    elsif !object.respond_to?(:id)
      raise ArgumentError, 'Object must have an id'
    end
  end

  # Validate that a type is not nil
  # @param type [Class] The type to validate
  # @raise [ArgumentError] If the type is nil
  def validate_type(type)
    raise ArgumentError, 'Type cannot be nil' if type.nil?
  end
end
