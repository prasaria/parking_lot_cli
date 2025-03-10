# lib/models/vehicle.rb

# The Vehicle class represents a vehicle that can park in the parking complex.
# This is an abstract base class that cannot be instantiated directly.
# Subclasses should be created for each specific vehicle size.
class Vehicle
  attr_reader :id, :size

  # Initialize a new vehicle with an ID and size
  # @param id [String] The unique identifier for the vehicle (e.g., license plate)
  # @param size [Symbol] The size of the vehicle (:small, :medium, or :large)
  # @raise [NotImplementedError] If trying to instantiate Vehicle directly
  def initialize(id, size)
    @id = id
    @size = size

    # Ensure Vehicle is treated as an abstract class
    raise NotImplementedError, 'Vehicle is an abstract class' if instance_of?(Vehicle)
  end

  # Determines if this vehicle can park in the given parking slot
  # @param slot [ParkingSlot] The parking slot to check compatibility with
  # @return [Boolean] true if the vehicle can park in the slot, false otherwise
  # @raise [NotImplementedError] If the subclass doesn't implement this method
  def can_park_in?(slot)
    raise NotImplementedError, 'Subclasses must implement #can_park_in?'
  end

  # Compare this vehicle with another object
  # Two vehicles are considered equal if they have the same ID
  # @param other [Object] The object to compare with
  # @return [Boolean] true if the vehicles are equal, false otherwise
  def ==(other)
    return false unless other.is_a?(Vehicle)

    id == other.id
  end

  # Alias eql? to == for hash equality
  alias eql? ==

  # Implement hash based on the id for consistent hash behavior
  # @return [Integer] The hash code
  def hash
    id.hash
  end
end
