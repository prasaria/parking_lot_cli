# frozen_string_literal: true

require_relative 'vehicle'

# Represents a small vehicle in the parking system
# Small vehicles can park in any type of parking slot (small, medium, or large)
class SmallVehicle < Vehicle
  # Initialize a new small vehicle with the given identifier
  # @param id [String] The vehicle identifier (e.g., license plate)
  def initialize(id)
    super(id, :small)
  end

  # Determines if this small vehicle can park in the given parking slot
  # According to the requirements, small vehicles can park in any slot type
  # @param slot [ParkingSlot] The parking slot to check
  # @return [Boolean] Always returns true for small vehicles
  def can_park_in?(slot)
    # Ensure the slot has a size property (will raise NoMethodError if not)
    slot.size
    true # Small vehicles can park in any type of slot
  end
end
