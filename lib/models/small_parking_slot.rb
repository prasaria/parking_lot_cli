# frozen_string_literal: true

require_relative 'parking_slot'

# Represents a small parking slot in the parking system
# Small parking slots can only fit small vehicles
class SmallParkingSlot < ParkingSlot
  # Initialize a new small parking slot with the given identifier and distances
  # @param id [Integer] The slot identifier
  # @param distances [Array<Integer>] The distances from each entry point
  def initialize(id, distances)
    super(id, :small, distances)
  end

  # Determines if this small parking slot can fit the given vehicle
  # According to the requirements, small parking slots can only fit small vehicles
  # @param vehicle [Vehicle] The vehicle to check
  # @return [Boolean] true if the vehicle is small, false otherwise
  # @raise [NoMethodError] If vehicle is nil or doesn't respond to size
  def can_fit?(vehicle)
    # Check vehicle size - must access vehicle.size which will
    # raise NoMethodError if vehicle is nil or doesn't have a size method
    vehicle.size == :small
  end
end
