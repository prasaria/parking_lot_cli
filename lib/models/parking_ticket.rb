# frozen_string_literal: true

# Represents a parking ticket issued when a vehicle is parked
# Records information about the vehicle, slot, entry point, and timestamps
class ParkingTicket
  attr_reader :vehicle, :slot, :entry_point, :entry_time, :exit_time

  # Initialize a new parking ticket
  # @param vehicle [Vehicle] The vehicle being parked
  # @param slot [ParkingSlot] The slot where the vehicle is parked
  # @param entry_point [EntryPoint] The entry point used by the vehicle
  # @param entry_time [Time] The time when the vehicle entered (defaults to current time)
  # @raise [ArgumentError] If any required parameter is nil
  def initialize(vehicle, slot, entry_point, entry_time = Time.now)
    validate_parameters(vehicle, slot, entry_point)

    @vehicle = vehicle
    @slot = slot
    @entry_point = entry_point
    @entry_time = entry_time
    @exit_time = nil
  end

  # Set the exit time for this ticket
  # @param time [Time] The exit time
  # @raise [ArgumentError] If time is invalid (nil, not a Time, or before entry time)
  def exit_time=(time)
    validate_exit_time(time)
    @exit_time = time
  end

  # Check if the ticket is still active (vehicle is still parked)
  # @return [Boolean] true if the vehicle is still parked, false otherwise
  def active?
    @exit_time.nil?
  end

  # Calculate the duration of parking in hours, rounded up
  # @return [Integer] The duration in hours
  # @raise [RuntimeError] If the ticket is still active
  def duration_in_hours
    raise 'Cannot calculate duration for active ticket' if active?

    # Calculate duration in seconds
    duration_seconds = @exit_time - @entry_time

    # Convert to hours and round up
    hours = (duration_seconds / 3600.0).ceil

    # Ensure minimum of 1 hour
    [1, hours].max
  end

  # Calculate the duration in complete days and remaining hours
  # @return [Array<Integer, Integer>] [days, hours]
  # @raise [RuntimeError] If the ticket is still active
  def duration_in_days_and_hours
    raise 'Cannot calculate duration for active ticket' if active?

    total_hours = duration_in_hours
    days = total_hours / 24
    remaining_hours = total_hours % 24

    [days, remaining_hours]
  end

  # String representation of the ticket
  # @return [String] A string containing ticket details
  def to_s
    status = active? ? 'ACTIVE' : 'CLOSED'
    time_info = if active?
                  "Entry: #{@entry_time}"
                else
                  "Entry: #{@entry_time}, Exit: #{@exit_time}, Duration: #{duration_in_hours}h"
                end

    "Ticket [#{status}] - Vehicle: #{@vehicle.id}, Slot: #{@slot.id}, #{time_info}"
  end

  private

  # Validate the required parameters
  # @param vehicle [Vehicle] The vehicle to validate
  # @param slot [ParkingSlot] The slot to validate
  # @param entry_point [EntryPoint] The entry point to validate
  # @raise [ArgumentError] If any parameter is nil
  def validate_parameters(vehicle, slot, entry_point)
    if vehicle.nil?
      raise ArgumentError, 'Vehicle cannot be nil'
    elsif slot.nil?
      raise ArgumentError, 'Parking slot cannot be nil'
    elsif entry_point.nil?
      raise ArgumentError, 'Entry point cannot be nil'
    end
  end

  # Validate the exit time
  # @param time [Time] The time to validate
  # @raise [ArgumentError] If time is invalid
  def validate_exit_time(time)
    if time.nil?
      raise ArgumentError, 'Exit time cannot be nil'
    elsif !time.is_a?(Time)
      raise ArgumentError, "Exit time must be a Time object, got #{time.class}"
    elsif time < @entry_time
      raise ArgumentError, 'Exit time cannot be before entry time'
    end
  end
end
