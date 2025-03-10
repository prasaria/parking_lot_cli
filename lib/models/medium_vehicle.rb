# frozen_string_literal: true

require_relative 'vehicle'

# Represents a medium vehicle in the parking system
# Medium vehicles can park in medium or large parking slots, but not in small slots
class MediumVehicle < Vehicle
  # Initialize a new medium vehicle with the given identifier
  # @param id [String] The vehicle identifier (e.g., license plate)
  def initialize(id)
    super(id, :medium)
  end

  # Determines if this medium vehicle can park in the given parking slot
  # According to the requirements, medium vehicles can park in medium and large slots
  # @param slot [ParkingSlot] The parking slot to check
  # @return [Boolean] true if the slot is medium or large, false otherwise
  def can_park_in?(slot)
    # Medium vehicles can only park in medium or large slots
    %i[medium large].include?(slot.size)
  end
end
