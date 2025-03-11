# frozen_string_literal: true

require 'models/small_vehicle'
require 'models/medium_vehicle'
require 'models/large_vehicle'

# Handles parsing and executing CLI commands for the parking system
class CommandHandler # rubocop:disable Metrics/ClassLength
  # Constructor
  # @param parking_complex [ParkingComplex] The parking complex to operate on
  def initialize(parking_complex)
    @parking_complex = parking_complex
  end

  # Parse a command string into command and arguments
  # @param command_str [String] The command string to parse
  # @return [Hash, nil] Hash with :command and :args keys, or nil if invalid
  def parse_command(command_str)
    return nil if command_str.nil? || command_str.strip.empty?

    parts = command_str.strip.split
    command = parts.shift.downcase
    args = parts

    { command: command, args: args }
  end

  # Execute a command
  # @param command_str [String] The command string to execute
  # @return [Hash] Hash with :success and :message keys
  def execute_command(command_str) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
    parsed = parse_command(command_str)

    # Handle special case for direct commands
    return handle_direct_command(command_str) unless parsed

    command = parsed[:command]
    args = parsed[:args]

    # Use a command map to avoid a long if/else chain
    command_map = {
      'help' => -> { execute_help },
      'status' => -> { execute_status },
      'park' => -> { execute_park(args) },
      'unpark' => -> { execute_unpark(args) },
      'slots' => -> { execute_slots(args) },
      'vehicles' => -> { execute_vehicles },
      'exit' => -> { execute_exit }
    }

    if command_map.key?(command)
      command_map[command].call
    else
      { success: false, message: "Unknown command: #{command}. Type 'help' for available commands." }
    end
  end

  private

  # Handle direct commands (help, exit)
  # @param command_str [String] The raw command string
  # @return [Hash] Command result
  def handle_direct_command(command_str)
    case command_str.strip.downcase
    when 'help'
      execute_help
    when 'exit'
      execute_exit
    else
      { success: false, message: 'Invalid command. Type \'help\' for available commands.' }
    end
  end

  # Execute the help command
  # @return [Hash] Command result
  def execute_help # rubocop:disable Metrics/MethodLength
    help_text = <<~HELP
      Available commands:

      help                    - Show this help message
      status                  - Show parking complex status
      park <id> <type> <entry>  - Park a vehicle (type: small, medium, large)
      unpark <id>             - Unpark a vehicle
      slots [type]            - List parking slots (type: small, medium, large)
      vehicles                - List parked vehicles
      exit                    - Exit the application
    HELP

    { success: true, message: help_text }
  end

  # Execute the status command
  # @return [Hash] Command result
  def execute_status # rubocop:disable Metrics/MethodLength
    status = <<~STATUS
      Parking Complex Status

      Entry Points: #{@parking_complex.entry_points.size}
      Parking Slots: #{@parking_complex.parking_slots.size}
      Parked Vehicles: #{@parking_complex.parked_vehicles_count}
      Available Slots: #{@parking_complex.available_parking_slots.size}

      Available Slots by Type:
      Small: #{@parking_complex.available_parking_slots(type: :small).size}
      Medium: #{@parking_complex.available_parking_slots(type: :medium).size}
      Large: #{@parking_complex.available_parking_slots(type: :large).size}
    STATUS

    { success: true, message: status }
  end

  # Execute the park command
  # @param args [Array<String>] Command arguments
  # @return [Hash] Command result
  def execute_park(args) # rubocop:disable Metrics/MethodLength
    # Validate arguments
    return invalid_command('park <id> <type> <entry>') if args.size < 3

    vehicle_id = args[0]
    vehicle_type = args[1].downcase
    entry_point_id = args[2].to_i

    # Create vehicle based on type
    vehicle = create_vehicle(vehicle_id, vehicle_type)
    return { success: false, message: "Invalid vehicle type: #{vehicle_type}" } unless vehicle

    # Get entry point
    entry_point = @parking_complex.get_entry_point(entry_point_id)
    return { success: false, message: "Entry point not found: #{entry_point_id}" } unless entry_point

    # Attempt to park the vehicle
    begin
      ticket = @parking_complex.park(vehicle, entry_point)
      if ticket
        format_park_success(ticket)
      else
        { success: false, message: "No available slot for #{vehicle_type} vehicle" }
      end
    rescue ArgumentError => e
      { success: false, message: "Could not park vehicle: #{e.message}" }
    end
  end

  # Create a vehicle of the specified type
  # @param id [String] Vehicle ID
  # @param type [String] Vehicle type (small, medium, large)
  # @return [Vehicle, nil] The created vehicle, or nil if invalid type
  def create_vehicle(id, type)
    case type
    when 'small' then SmallVehicle.new(id)
    when 'medium' then MediumVehicle.new(id)
    when 'large' then LargeVehicle.new(id)
    end
  end

  # Format success message for park command
  # @param ticket [ParkingTicket] The parking ticket
  # @return [Hash] Command result
  def format_park_success(ticket)
    message = <<~MESSAGE
      Vehicle #{ticket.vehicle.id} parked successfully

      Ticket Details:
      Slot ID: #{ticket.slot.id}
      Slot Type: #{ticket.slot.size}
      Entry Point: #{ticket.entry_point.id}
      Entry Time: #{ticket.entry_time}
    MESSAGE

    { success: true, message: message }
  end

  # Execute the unpark command
  # @param args [Array<String>] Command arguments
  # @return [Hash] Command result
  def execute_unpark(args)
    # Validate arguments
    return invalid_command('unpark <id>') if args.empty?

    vehicle_id = args[0]

    # Find the vehicle
    begin
      # We need to find the actual vehicle object
      # In a real implementation, we'd have a repository to look up vehicles
      # For this simple example, find all vehicles tracked by the complex
      vehicle = find_vehicle_by_id(vehicle_id)
      return { success: false, message: "Vehicle #{vehicle_id} is not parked" } unless vehicle

      # Unpark the vehicle
      ticket = @parking_complex.unpark(vehicle)
      format_unpark_success(ticket)
    rescue ArgumentError => e
      { success: false, message: "Could not unpark vehicle: #{e.message}" }
    end
  end

  # Find a vehicle by ID
  # @param id [String] Vehicle ID
  # @return [Vehicle, nil] The vehicle, or nil if not found
  def find_vehicle_by_id(id)
    # In a real implementation, we'd look this up in a repository
    # For this simple CLI, we'll just check the tracker
    all_vehicles = @parking_complex.tracker.instance_variable_get(:@currently_parked)
    vehicle_ticket = all_vehicles[id]
    vehicle_ticket&.vehicle
  end

  # Format success message for unpark command
  # @param ticket [ParkingTicket] The parking ticket
  # @return [Hash] Command result
  def format_unpark_success(ticket) # rubocop:disable Metrics/MethodLength
    duration_hours = ticket.duration_in_hours

    message = <<~MESSAGE
      Vehicle #{ticket.vehicle.id} unparked successfully

      Ticket Details:
      Slot ID: #{ticket.slot.id}
      Slot Type: #{ticket.slot.size}
      Entry Time: #{ticket.entry_time}
      Exit Time: #{ticket.exit_time}
      Duration: #{duration_hours} hours
      Fee: #{ticket.fee} pesos
    MESSAGE

    { success: true, message: message }
  end

  # Execute the slots command
  # @param args [Array<String>] Command arguments
  # @return [Hash] Command result
  def execute_slots(args)
    # First handle case with filter by type
    return list_slots_by_type(args[0]) if args.size == 1

    # List all slots
    list_all_slots
  end

  # List slots filtered by type
  # @param type_str [String] Slot type (small, medium, large)
  # @return [Hash] Command result
  def list_slots_by_type(type_str)
    type_map = {
      'small' => :small,
      'medium' => :medium,
      'large' => :large
    }

    type_sym = type_map[type_str.downcase]
    return { success: false, message: "Invalid slot type: #{type_str}" } unless type_sym

    slots = @parking_complex.parking_slots.select { |slot| slot.size == type_sym }
    format_slots_list("#{type_str.capitalize} Parking Slots", slots)
  end

  # List all slots
  # @return [Hash] Command result
  def list_all_slots
    format_slots_list('Parking Slots', @parking_complex.parking_slots)
  end

  # Format a list of slots as a message
  # @param title [String] The title for the list
  # @param slots [Array<ParkingSlot>] The slots to list
  # @return [Hash] Command result
  def format_slots_list(title, slots)
    return { success: true, message: "No #{title.downcase} found" } if slots.empty?

    slot_details = slots.map do |slot|
      status = slot.available? ? 'Available' : 'Occupied'
      "ID: #{slot.id}, Type: #{slot.size}, Status: #{status}"
    end.join("\n")

    message = <<~MESSAGE
      #{title} (#{slots.size})

      #{slot_details}
    MESSAGE

    { success: true, message: message }
  end

  # Execute the vehicles command
  # @return [Hash] Command result
  def execute_vehicles
    # In a real implementation, we'd get this from the repository
    # For this simple CLI, we'll just check the tracker
    all_vehicles = @parking_complex.tracker.instance_variable_get(:@currently_parked)

    return { success: true, message: 'No vehicles currently parked' } if all_vehicles.empty?

    vehicle_details = all_vehicles.map do |id, ticket|
      "ID: #{id}, Type: #{ticket.vehicle.size}, Slot: #{ticket.slot.id}"
    end.join("\n")

    message = <<~MESSAGE
      Parked Vehicles (#{all_vehicles.size})

      #{vehicle_details}
    MESSAGE

    { success: true, message: message }
  end

  # Execute the exit command
  # @return [Hash] Command result
  def execute_exit
    { success: true, message: 'Exiting the parking system. Goodbye!' }
  end

  # Format an invalid command message
  # @param usage [String] The correct command usage
  # @return [Hash] Command result
  def invalid_command(usage)
    { success: false, message: "Invalid command format. Usage: #{usage}" }
  end
end
