# frozen_string_literal: true

require_relative 'parking_slot'

# Represents a large parking slot in the parking system
# Large parking slots can fit any type of vehicle (small, medium, or large)
class LargeParkingSlot < ParkingSlot
  # Initialize a new large parking slot with the given identifier and distances
  # @param id [Integer] The slot identifier
  # @param distances [Array<Integer>] The distances from each entry point
  def initialize(id, distances)
    super(id, :large, distances)
  end

  # Determines if this large parking slot can fit the given vehicle
  # According to the requirements, large parking slots can fit any vehicle type
  # @param vehicle [Vehicle] The vehicle to check
  # @return [Boolean] Always returns true as long as vehicle has a valid size
  # @raise [NoMethodError] If vehicle is nil or doesn't respond to size
  def can_fit?(vehicle)
    # Check vehicle size to ensure the vehicle is valid
    # This will raise NoMethodError if vehicle is nil or doesn't have a size method
    vehicle.size

    # Large slots can fit any vehicle type
    true
  end
end
