# frozen_string_literal: true

require_relative 'vehicle'

# Represents a large vehicle in the parking system
# Large vehicles can only park in large parking slots
class LargeVehicle < Vehicle
  # Initialize a new large vehicle with the given identifier
  # @param id [String] The vehicle identifier (e.g., license plate)
  def initialize(id)
    super(id, :large)
  end

  # Determines if this large vehicle can park in the given parking slot
  # According to the requirements, large vehicles can only park in large slots
  # @param slot [ParkingSlot] The parking slot to check
  # @return [Boolean] true if the slot is large, false otherwise
  # @raise [NoMethodError] If slot is nil or doesn't respond to size
  def can_park_in?(slot)
    # Large vehicles can only park in large slots
    slot.size == :large
  end
end
