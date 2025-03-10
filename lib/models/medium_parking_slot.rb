# frozen_string_literal: true

require_relative 'parking_slot'

# Represents a medium parking slot in the parking system
# Medium parking slots can fit small and medium vehicles
class MediumParkingSlot < ParkingSlot
  # Initialize a new medium parking slot with the given identifier and distances
  # @param id [Integer] The slot identifier
  # @param distances [Array<Integer>] The distances from each entry point
  def initialize(id, distances)
    super(id, :medium, distances)
  end

  # Determines if this medium parking slot can fit the given vehicle
  # According to the requirements, medium parking slots can fit small and medium vehicles
  # @param vehicle [Vehicle] The vehicle to check
  # @return [Boolean] true if the vehicle is small or medium, false otherwise
  # @raise [NoMethodError] If vehicle is nil or doesn't respond to size
  def can_fit?(vehicle)
    # Check vehicle size - will raise NoMethodError if vehicle is nil
    # or doesn't have a size method
    %i[small medium].include?(vehicle.size)
  end
end
