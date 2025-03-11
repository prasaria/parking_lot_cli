# frozen_string_literal: true

require 'spec_helper'
require_relative '../main'

RSpec.describe 'Parking System Main Program' do
  # Mock standard input/output for testing
  let(:input) { StringIO.new }
  let(:output) { StringIO.new }

  # Create a test instance of the program with mocked IO
  let(:program) { ParkingSystem.new(input: input, output: output) }

  describe '#initialize' do
    it 'creates a valid parking system with default configuration' do
      expect(program.menu).not_to be_nil
      expect(program.parking_complex).not_to be_nil
      expect(program.command_handler).not_to be_nil
      expect(program.formatter).not_to be_nil
    end

    it 'initializes parking slots with the specified configuration' do
      # Verify that the right number of slots are created
      expect(program.parking_complex.parking_slots.size).to eq(6)

      # Verify slot types distribution
      small_slots = program.parking_complex.parking_slots.select { |s| s.size == :small }
      medium_slots = program.parking_complex.parking_slots.select { |s| s.size == :medium }
      large_slots = program.parking_complex.parking_slots.select { |s| s.size == :large }

      expect(small_slots.size).to eq(2)
      expect(medium_slots.size).to eq(2)
      expect(large_slots.size).to eq(2)
    end

    it 'initializes entry points with the specified configuration' do
      # Verify that the right number of entry points are created
      expect(program.parking_complex.entry_points.size).to eq(3)

      # Verify entry point IDs
      entry_point_ids = program.parking_complex.entry_points.map(&:id)
      expect(entry_point_ids).to contain_exactly(0, 1, 2)
    end
  end

  describe '#setup_parking_complex' do
    it 'creates a parking complex with the specified configuration' do
      # Access the method through the program's instance
      parking_complex = program.send(:setup_parking_complex)

      # Verify that the parking complex has the right components
      expect(parking_complex.entry_points.size).to eq(3)
      expect(parking_complex.parking_slots.size).to eq(6)
      expect(parking_complex.repository).to be_a(InMemoryRepository)
      expect(parking_complex.allocator).to be_a(ParkingAllocator)
      expect(parking_complex.calculator).to be_a(FeeCalculator)
      expect(parking_complex.tracker).to be_a(VehicleTracker)
    end
  end

  describe '#setup_entry_points' do
    it 'creates the specified number of entry points' do
      entry_points = program.send(:setup_entry_points, 5)

      expect(entry_points.size).to eq(5)
      expect(entry_points.map(&:id)).to eq([0, 1, 2, 3, 4])
    end
  end

  describe '#setup_parking_slots' do
    it 'creates parking slots with the specified configuration' do
      entry_points = program.send(:setup_entry_points, 3)
      slots = program.send(:setup_parking_slots, entry_points)

      expect(slots.size).to eq(6)

      # Verify slot types
      slot_types = slots.map(&:size)
      expect(slot_types.count(:small)).to eq(2)
      expect(slot_types.count(:medium)).to eq(2)
      expect(slot_types.count(:large)).to eq(2)

      # Verify slot distances
      slots.each do |slot|
        expect(slot.distances.size).to eq(entry_points.size)
      end
    end
  end

  describe '#start' do
    it 'starts the menu' do
      # Mock the menu to prevent infinite loop
      allow(program.menu).to receive(:start)

      program.start

      # Verify that menu.start was called
      expect(program.menu).to have_received(:start)
    end
  end
end
