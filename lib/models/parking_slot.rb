# frozen_string_literal: true

# The ParkingSlot class represents a parking slot in the parking complex.
# This is an abstract base class that cannot be instantiated directly.
# Subclasses should be created for each specific parking slot size.
class ParkingSlot
  # Valid sizes for parking slots
  VALID_SIZES = %i[small medium large].freeze

  attr_reader :id, :size, :distances

  # Initialize a new parking slot with an ID, size, and distances from entry points
  # @param id [Integer] The unique identifier for the parking slot
  # @param size [Symbol] The size of the parking slot (:small, :medium, or :large)
  # @param distances [Array<Integer>] The distances from each entry point
  # @raise [NotImplementedError] If trying to instantiate ParkingSlot directly
  # @raise [ArgumentError] If size is invalid or distances are not properly formatted
  def initialize(id, size, distances)
    @id = id
    validate_size(size)
    @size = size
    validate_distances(distances)
    @distances = distances.dup.freeze # Create a frozen copy to prevent modification
    @available = true # Initially, all slots are available

    # Ensure ParkingSlot is treated as an abstract class
    raise NotImplementedError, 'ParkingSlot is an abstract class' if instance_of?(ParkingSlot)
  end

  # Determines if this slot can fit the given vehicle
  # @param vehicle [Vehicle] The vehicle to check compatibility with
  # @return [Boolean] true if the vehicle can fit in this slot, false otherwise
  # @raise [NotImplementedError] If the subclass doesn't implement this method
  def can_fit?(vehicle)
    raise NotImplementedError, 'Subclasses must implement #can_fit?'
  end

  # Get the distance from this slot to a specific entry point
  # @param entry_point [EntryPoint] The entry point to measure distance from
  # @return [Integer] The distance in distance units
  # @raise [IndexError] If the entry point ID is out of range
  def distance_from(entry_point)
    entry_point_id = entry_point.id
    if entry_point_id >= @distances.length
      raise IndexError,
            "Entry point ID #{entry_point_id} is out of range"
    end

    @distances[entry_point_id]
  end

  # Check if the slot is available
  # @return [Boolean] true if the slot is available, false otherwise
  def available?
    @available
  end

  # Mark the slot as occupied
  def occupy
    @available = false
  end

  # Mark the slot as vacant
  def vacate
    @available = true
  end

  # Compare this slot with another object
  # Two slots are considered equal if they have the same ID
  # @param other [Object] The object to compare with
  # @return [Boolean] true if the slots are equal, false otherwise
  def ==(other)
    return false unless other.is_a?(ParkingSlot)

    id == other.id
  end

  # Alias eql? to == for hash equality
  alias eql? ==

  # Implement hash based on the id for consistent hash behavior
  # @return [Integer] The hash code
  def hash
    id.hash
  end

  private

  # Validate the size parameter
  # @param size [Symbol] The size to validate
  # @raise [ArgumentError] If the size is not one of the valid sizes
  def validate_size(size)
    return if VALID_SIZES.include?(size)

    raise ArgumentError, "Invalid size: #{size}. Must be one of: #{VALID_SIZES.join(', ')}"
  end

  # Validate the distances parameter
  # @param distances [Array] The distances to validate
  # @raise [ArgumentError] If the distances are not properly formatted
  def validate_distances(distances)
    raise ArgumentError, "Distances must be an array, got #{distances.class}" unless distances.is_a?(Array)

    raise ArgumentError, 'Distances array cannot be empty' if distances.empty?

    return if distances.all? { |d| d.is_a?(Numeric) }

    raise ArgumentError, 'All distances must be numeric values'
  end
end
