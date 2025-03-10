# frozen_string_literal: true

# Service responsible for tracking vehicles entering and exiting the parking complex
# Maintains the state of currently parked vehicles and their parking history
class VehicleTracker
  def initialize
    @currently_parked = {} # Maps vehicle ID to active ticket
    @vehicle_history = {}  # Maps vehicle ID to array of tickets (history)
    @exit_times = {}       # Maps vehicle ID to most recent exit time
  end

  # Track a vehicle entering the parking complex
  # @param ticket [ParkingTicket] The ticket issued to the entering vehicle
  # @raise [ArgumentError] If the ticket is nil or the vehicle is already parked
  def track_vehicle_entry(ticket)
    validate_entry_ticket(ticket)

    vehicle = ticket.vehicle

    # Store the ticket in the currently parked vehicles
    @currently_parked[vehicle.id] = ticket

    # Add ticket to the vehicle's history
    @vehicle_history[vehicle.id] ||= []
    @vehicle_history[vehicle.id] << ticket
  end

  # Track a vehicle exiting the parking complex
  # @param ticket [ParkingTicket] The ticket of the exiting vehicle
  # @raise [ArgumentError] If the ticket is nil, has no exit time, or the vehicle is not parked
  def track_vehicle_exit(ticket)
    validate_exit_ticket(ticket)

    vehicle = ticket.vehicle

    # Remove from currently parked vehicles
    @currently_parked.delete(vehicle.id)

    # Store the exit time
    @exit_times[vehicle.id] = ticket.exit_time
  end

  # Check if a vehicle is currently parked
  # @param vehicle [Vehicle] The vehicle to check
  # @return [Boolean] true if the vehicle is currently parked, false otherwise
  def currently_parked?(vehicle)
    @currently_parked.key?(vehicle.id)
  end

  # Get the active ticket for a parked vehicle
  # @param vehicle [Vehicle] The vehicle to get the ticket for
  # @return [ParkingTicket, nil] The active ticket if the vehicle is parked, nil otherwise
  def get_active_ticket(vehicle)
    @currently_parked[vehicle.id]
  end

  # Check if a vehicle exited the parking complex recently
  # @param vehicle [Vehicle] The vehicle to check
  # @param check_time [Time] The time to check against
  # @param window_hours [Integer, Float] The time window in hours (default: 1)
  # @return [Boolean] true if the vehicle exited within the specified time window, false otherwise
  def recently_exited?(vehicle, check_time, window_hours = 1)
    return false unless @exit_times.key?(vehicle.id)

    exit_time = @exit_times[vehicle.id]
    time_since_exit = check_time - exit_time

    # Convert time difference to hours and check if within window
    time_since_exit / 3600.0 <= window_hours
  end

  # Get the previous ticket for a vehicle that has exited
  # @param vehicle [Vehicle] The vehicle to get the ticket for
  # @return [ParkingTicket, nil] The most recent ticket if the vehicle has exited, nil otherwise
  def get_previous_ticket(vehicle)
    # If vehicle is currently parked, it has no previous ticket
    return nil if currently_parked?(vehicle)

    # Return the most recent ticket from the history
    history = get_tickets_history(vehicle)
    history.empty? ? nil : history.last
  end

  # Get all tickets for a vehicle
  # @param vehicle [Vehicle] The vehicle to get the tickets for
  # @return [Array<ParkingTicket>] Array of all tickets for the vehicle (empty if none)
  def get_tickets_history(vehicle)
    @vehicle_history[vehicle.id] || []
  end

  # Get the most recent exit time for a vehicle
  # @param vehicle [Vehicle] The vehicle to get the exit time for
  # @return [Time, nil] The most recent exit time, or nil if the vehicle has never exited
  def get_last_exit_time(vehicle)
    @exit_times[vehicle.id]
  end

  # Check if this would be the first time the vehicle is parking
  # @param vehicle [Vehicle] The vehicle to check
  # @return [Boolean] true if the vehicle has never been parked before, false otherwise
  def first_time_parking?(vehicle)
    !@vehicle_history.key?(vehicle.id) || @vehicle_history[vehicle.id].empty?
  end

  private

  # Validate a ticket for vehicle entry
  # @param ticket [ParkingTicket] The ticket to validate
  # @raise [ArgumentError] If the ticket is nil or the vehicle is already parked
  def validate_entry_ticket(ticket)
    if ticket.nil?
      raise ArgumentError, 'Ticket cannot be nil'
    elsif currently_parked?(ticket.vehicle)
      raise ArgumentError, "Vehicle #{ticket.vehicle.id} is already parked"
    end
  end

  # Validate a ticket for vehicle exit
  # @param ticket [ParkingTicket] The ticket to validate
  # @raise [ArgumentError] If the ticket is nil, has no exit time, or the vehicle is not parked
  def validate_exit_ticket(ticket)
    if ticket.nil?
      raise ArgumentError, 'Ticket cannot be nil'
    elsif ticket.exit_time.nil?
      raise ArgumentError, 'Ticket must have an exit time'
    elsif !currently_parked?(ticket.vehicle)
      raise ArgumentError, "Vehicle #{ticket.vehicle.id} is not currently parked"
    end
  end
end
