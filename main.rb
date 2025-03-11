#!/usr/bin/env ruby
# frozen_string_literal: true

# Load path setup
$LOAD_PATH.unshift File.join(File.dirname(__FILE__), 'lib')

# Require all the necessary files
require 'models/parking_complex'
require 'models/entry_point'
require 'models/small_parking_slot'
require 'models/medium_parking_slot'
require 'models/large_parking_slot'
require 'services/parking_allocator'
require 'services/fee_calculator'
require 'services/vehicle_tracker'
require 'repositories/in_memory_repository'
require 'cli/command_handler'
require 'cli/formatter'
require 'cli/menu'

# Main class for the Parking System application
class ParkingSystem
  attr_reader :parking_complex, :command_handler, :formatter, :menu

  # Initialize the parking system
  # @param input [IO] Input stream (defaults to STDIN)
  # @param output [IO] Output stream (defaults to STDOUT)
  def initialize(input: $stdin, output: $stdout)
    # Setup the parking complex with all components
    @parking_complex = setup_parking_complex

    # Setup the CLI components
    @command_handler = CommandHandler.new(@parking_complex)
    @formatter = Formatter.new
    @menu = Menu.new(@command_handler, @formatter, input: input, output: output)
  end

  # Start the parking system
  def start
    @menu.start
  end

  private

  # Setup the parking complex with entry points, slots, and services
  # @return [ParkingComplex] The initialized parking complex
  def setup_parking_complex # rubocop:disable Metrics/MethodLength
    # Create entry points - minimum of 3 as per requirements
    entry_points = setup_entry_points(3)

    # Create parking slots with distances from entry points
    parking_slots = setup_parking_slots(entry_points)

    # Create services
    repository = InMemoryRepository.new
    allocator = ParkingAllocator.new
    calculator = FeeCalculator.new
    tracker = VehicleTracker.new

    # Create and return the parking complex
    ParkingComplex.new(
      entry_points,
      parking_slots,
      repository: repository,
      allocator: allocator,
      calculator: calculator,
      tracker: tracker
    )
  end

  # Setup entry points
  # @param count [Integer] Number of entry points to create
  # @return [Array<EntryPoint>] Array of entry points
  def setup_entry_points(count)
    (0...count).map { |i| EntryPoint.new(i) }
  end

  # Setup parking slots with distances from entry points
  # @param entry_points [Array<EntryPoint>] The entry points
  # @return [Array<ParkingSlot>] Array of parking slots
  def setup_parking_slots(_entry_points)
    slots = []

    # Create small parking slots
    slots << SmallParkingSlot.new(1, [1, 5, 8]) # Distances from entry points 0, 1, 2
    slots << SmallParkingSlot.new(2, [2, 6, 9])

    # Create medium parking slots
    slots << MediumParkingSlot.new(3, [3, 2, 10])
    slots << MediumParkingSlot.new(4, [4, 3, 7])

    # Create large parking slots
    slots << LargeParkingSlot.new(5, [6, 1, 5])
    slots << LargeParkingSlot.new(6, [7, 4, 2])

    slots
  end
end

# Run the application if this file is executed directly
if __FILE__ == $PROGRAM_NAME
  begin
    system = ParkingSystem.new
    system.start
  rescue StandardError => e
    puts "An error occurred: #{e.message}"
    puts e.backtrace
    exit(1)
  end
end
