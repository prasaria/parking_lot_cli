# frozen_string_literal: true

require 'repositories/in_memory_repository'
require 'services/parking_allocator'
require 'services/fee_calculator'
require 'services/vehicle_tracker'
require 'models/parking_slot'
require 'models/small_parking_slot'
require 'models/medium_parking_slot'
require 'models/large_parking_slot'

# Configuration object for initializing ParkingComplex
class ParkingComplexConfig
  attr_reader :repository, :allocator, :calculator, :tracker

  def initialize(repository: nil, allocator: nil, calculator: nil, tracker: nil)
    @repository = repository || InMemoryRepository.new
    @allocator = allocator || ParkingAllocator.new
    @calculator = calculator || FeeCalculator.new
    @tracker = tracker || VehicleTracker.new
  end
end

# Represents a parking complex with entry points and parking slots
# Manages parking operations and fee calculations
class ParkingComplex # rubocop:disable Metrics/ClassLength
  attr_reader :entry_points, :parking_slots, :repository, :allocator, :calculator, :tracker

  # Initialize a new parking complex
  # @param entry_points [Array<EntryPoint>] The entry points to the parking complex
  # @param parking_slots [Array<ParkingSlot>] The parking slots in the complex
  # @param config [ParkingComplexConfig, Hash] Configuration options
  # @option config [InMemoryRepository] :repository The repository to use
  # @option config [ParkingAllocator] :allocator The parking allocator to use
  # @option config [FeeCalculator] :calculator The fee calculator to use
  # @option config [VehicleTracker] :tracker The vehicle tracker to use
  # @raise [ArgumentError] If entry points or parking slots are invalid
  def initialize(entry_points, parking_slots, config = {})
    validate_entry_points(entry_points)
    validate_parking_slots(entry_points, parking_slots)

    @entry_points = entry_points.dup
    @parking_slots = parking_slots.dup

    # Handle configuration
    config = ParkingComplexConfig.new(**config) if config.is_a?(Hash)
    @repository = config.repository
    @allocator = config.allocator
    @calculator = config.calculator
    @tracker = config.tracker

    # Store entry points and parking slots in the repository
    store_initial_objects
  end

  # Get the number of currently parked vehicles
  # @return [Integer] The number of parked vehicles
  def parked_vehicles_count
    @tracker.currently_parked_count
  end

  # Get an entry point by ID
  # @param id [Integer] The ID of the entry point
  # @return [EntryPoint, nil] The entry point, or nil if not found
  def get_entry_point(id)
    @entry_points.find { |ep| ep.id == id }
  end

  # Add a new entry point to the parking complex
  # @param entry_point [EntryPoint] The entry point to add
  # @raise [ArgumentError] If the entry point is invalid or has a duplicate ID
  def add_entry_point(entry_point)
    validate_entry_point(entry_point)

    # Check for duplicate ID
    raise ArgumentError, "Entry point with ID #{entry_point.id} already exists" if @entry_points.any? { |ep| ep.id == entry_point.id }

    # Update slots to have distance from this entry point
    # This is a placeholder - in a real implementation, you'd need to provide distances
    # for each existing slot from this new entry point

    # Add the entry point
    @entry_points << entry_point
    @repository.add(entry_point)
  end

  # Get a parking slot by ID
  # @param id [Integer] The ID of the parking slot
  # @return [ParkingSlot, nil] The parking slot, or nil if not found
  def get_parking_slot(id)
    @parking_slots.find { |ps| ps.id == id }
  end

  # Get all available parking slots
  # @param type [Symbol, nil] The type of parking slots to get (:small, :medium, :large)
  # @return [Array<ParkingSlot>] Array of available parking slots
  def available_parking_slots(type: nil)
    slots = @parking_slots.select(&:available?)

    if type
      slots.select { |slot| slot.size == type }
    else
      slots
    end
  end

  # Add a new parking slot to the parking complex
  # @param parking_slot [ParkingSlot] The parking slot to add
  # @raise [ArgumentError] If the parking slot is invalid or has a duplicate ID
  def add_parking_slot(parking_slot)
    validate_parking_slot(@entry_points, parking_slot)

    # Check for duplicate ID
    raise ArgumentError, "Parking slot with ID #{parking_slot.id} already exists" if @parking_slots.any? { |ps| ps.id == parking_slot.id }

    # Add the parking slot
    @parking_slots << parking_slot
    @repository.add(parking_slot)
  end

  # Park a vehicle at an entry point
  # @param vehicle [Vehicle] The vehicle to park
  # @param entry_point [EntryPoint] The entry point the vehicle is entering from
  # @return [ParkingTicket, nil] The parking ticket if successful, nil if no slot available
  # @raise [ArgumentError] If the vehicle or entry point is invalid, or the vehicle is already parked
  def park(vehicle, entry_point) # rubocop:disable Metrics/MethodLength
    validate_parking_request(vehicle, entry_point)

    # Find the closest available compatible slot
    available_slots = @parking_slots.select(&:available?)
    slot = @allocator.find_slot(vehicle, available_slots, entry_point)

    # If no slot available, return nil
    return nil if slot.nil?

    # Mark the slot as occupied
    slot.occupy

    # Create a parking ticket
    entry_time = Time.now
    ticket = ParkingTicket.new(vehicle, slot, entry_point, entry_time)

    # Check for continuous rate (vehicle returning within 1 hour)
    apply_continuous_rate(ticket, vehicle)

    # Track the vehicle entry
    @tracker.track_vehicle_entry(ticket)

    # Store the ticket in the repository
    @repository.add(ticket)

    # Return the ticket
    ticket
  end

  # Unpark a vehicle
  # @param vehicle [Vehicle] The vehicle to unpark
  # @param exit_time [Time] The time the vehicle is exiting (default: current time)
  # @return [ParkingTicket] The completed parking ticket
  # @raise [ArgumentError] If the vehicle is invalid or not parked
  def unpark(vehicle, exit_time = Time.now)
    # Basic validation
    raise ArgumentError, 'Vehicle cannot be nil' if vehicle.nil?

    # Check if vehicle is parked
    raise ArgumentError, "Vehicle #{vehicle.id} is not parked" unless @tracker.currently_parked?(vehicle)

    # Get the active ticket
    ticket = @tracker.get_active_ticket(vehicle)

    # Set the exit time
    ticket.exit_time = exit_time

    # Get the parking slot and mark it available
    slot = ticket.slot
    slot.vacate

    # Track the vehicle exit
    @tracker.track_vehicle_exit(ticket)

    # Update the ticket in the repository
    @repository.add(ticket)

    # Return the completed ticket
    ticket
  end

  private

  # Validate the entry points
  # @param entry_points [Array<EntryPoint>] The entry points to validate
  # @raise [ArgumentError] If the entry points are invalid
  def validate_entry_points(entry_points)
    raise ArgumentError, 'Entry points cannot be nil or empty' if entry_points.nil? || entry_points.empty?

    raise ArgumentError, 'There must be at least 3 entry points' if entry_points.size < 3

    # Check that all entry points are valid
    entry_points.each { |ep| validate_entry_point(ep) }

    # Check for duplicate IDs
    entry_point_ids = entry_points.map(&:id)
    return unless entry_point_ids.uniq.size != entry_point_ids.size

    raise ArgumentError, 'Entry points must have unique IDs'
  end

  # Validate a single entry point
  # @param entry_point [EntryPoint] The entry point to validate
  # @raise [ArgumentError] If the entry point is invalid
  def validate_entry_point(entry_point)
    return if entry_point.is_a?(EntryPoint)

    raise ArgumentError, "Invalid entry point: #{entry_point.inspect}"
  end

  # Validate the parking slots
  # @param entry_points [Array<EntryPoint>] The entry points to validate against
  # @param parking_slots [Array<ParkingSlot>] The parking slots to validate
  # @raise [ArgumentError] If the parking slots are invalid
  def validate_parking_slots(entry_points, parking_slots)
    raise ArgumentError, 'Parking slots cannot be nil or empty' if parking_slots.nil? || parking_slots.empty?

    # Check that all parking slots are valid
    parking_slots.each { |ps| validate_parking_slot(entry_points, ps) }

    # Check for duplicate IDs
    parking_slot_ids = parking_slots.map(&:id)
    return unless parking_slot_ids.uniq.size != parking_slot_ids.size

    raise ArgumentError, 'Parking slots must have unique IDs'
  end

  # Validate a single parking slot
  # @param entry_points [Array<EntryPoint>] The entry points to validate against
  # @param parking_slot [ParkingSlot] The parking slot to validate
  # @raise [ArgumentError] If the parking slot is invalid
  def validate_parking_slot(entry_points, parking_slot)
    raise ArgumentError, "Invalid parking slot: #{parking_slot.inspect}" unless parking_slot.is_a?(ParkingSlot)

    # Check that the parking slot has the correct number of distances
    return unless parking_slot.distances.size != entry_points.size

    raise ArgumentError,
          "Parking slot #{parking_slot.id} has #{parking_slot.distances.size} distances, but there are #{entry_points.size} entry points"
  end

  # Validate the parking request
  # @param vehicle [Vehicle] The vehicle to validate
  # @param entry_point [EntryPoint] The entry point to validate
  # @raise [ArgumentError] If the vehicle or entry point is invalid, or the vehicle is already parked
  def validate_parking_request(vehicle, entry_point)
    # Check vehicle
    raise ArgumentError, 'Vehicle cannot be nil' if vehicle.nil?

    # Check entry point
    raise ArgumentError, 'Entry point cannot be nil' if entry_point.nil?

    raise ArgumentError, "Invalid entry point: #{entry_point.inspect}" unless entry_point.is_a?(EntryPoint)

    raise ArgumentError, "Entry point not found in this parking complex: #{entry_point.inspect}" unless @entry_points.include?(entry_point)

    # Check if vehicle is already parked
    return unless @tracker.currently_parked?(vehicle)

    raise ArgumentError, "Vehicle #{vehicle.id} is already parked"
  end

  # Apply continuous rate if applicable
  # @param ticket [ParkingTicket] The new ticket
  # @param vehicle [Vehicle] The vehicle
  def apply_continuous_rate(ticket, vehicle)
    # Check if the vehicle recently exited (within 1 hour)
    return unless @tracker.recently_exited?(vehicle, Time.now)

    # Get the previous ticket
    previous_ticket = @tracker.get_previous_ticket(vehicle)

    # Link the tickets for continuous rate
    ticket.previous_ticket = previous_ticket if previous_ticket
  end

  # Store the initial objects in the repository
  def store_initial_objects
    @entry_points.each { |ep| @repository.add(ep) }
    @parking_slots.each { |ps| @repository.add(ps) }
  end
end
