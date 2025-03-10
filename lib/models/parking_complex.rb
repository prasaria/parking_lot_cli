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
class ParkingComplex
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
    @repository.find(EntryPoint, id)
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
    # Search for the slot in all parking slot types
    [SmallParkingSlot, MediumParkingSlot, LargeParkingSlot].each do |slot_class|
      slot = @repository.find(slot_class, id)
      return slot if slot
    end
    nil
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

  # Store the initial objects in the repository
  def store_initial_objects
    @entry_points.each { |ep| @repository.add(ep) }
    @parking_slots.each { |ps| @repository.add(ps) }
  end
end
