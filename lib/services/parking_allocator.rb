# frozen_string_literal: true

# Service responsible for finding the closest available parking slot
# for a vehicle entering through a specific entry point
class ParkingAllocator
  # Find the closest available parking slot that is compatible with the given vehicle
  # @param vehicle [Vehicle] The vehicle to find a slot for
  # @param slots [Array<ParkingSlot>] The list of all parking slots
  # @param entry_point [EntryPoint] The entry point the vehicle is entering from
  # @return [ParkingSlot, nil] The closest compatible slot, or nil if none found
  # @raise [ArgumentError] If any required parameter is nil
  def find_slot(vehicle, slots, entry_point)
    validate_parameters(vehicle, slots, entry_point)

    # Filter out slots that are unavailable or incompatible with the vehicle
    compatible_slots = slots.select do |slot|
      slot.available? && compatible?(vehicle, slot)
    end

    # If no compatible slots, return nil
    return nil if compatible_slots.empty?

    # Find the closest slot based on distance from entry point
    find_closest_slot(compatible_slots, entry_point)
  end

  private

  # Validate the required parameters
  # @param vehicle [Vehicle] The vehicle to validate
  # @param slots [Array<ParkingSlot>] The slots to validate
  # @param entry_point [EntryPoint] The entry point to validate
  # @raise [ArgumentError] If any parameter is nil
  def validate_parameters(vehicle, slots, entry_point)
    if vehicle.nil?
      raise ArgumentError, 'Vehicle cannot be nil'
    elsif slots.nil?
      raise ArgumentError, 'Slots cannot be nil'
    elsif entry_point.nil?
      raise ArgumentError, 'Entry point cannot be nil'
    end
  end

  # Check if a vehicle is compatible with a parking slot
  # @param vehicle [Vehicle] The vehicle to check
  # @param slot [ParkingSlot] The slot to check
  # @return [Boolean] True if the vehicle can park in the slot
  def compatible?(vehicle, slot)
    # Use the vehicle's can_park_in? method to check compatibility
    vehicle.can_park_in?(slot)
  end

  # Find the closest slot from a list of compatible slots
  # @param compatible_slots [Array<ParkingSlot>] The list of compatible slots
  # @param entry_point [EntryPoint] The entry point to measure distance from
  # @return [ParkingSlot] The closest slot
  def find_closest_slot(compatible_slots, entry_point)
    # Sort slots by distance from entry point (and by ID for tie-breaking)
    compatible_slots.min_by do |slot|
      [slot.distance_from(entry_point), slot.id]
    end
  end
end
