# frozen_string_literal: true

require 'spec_helper'
require 'models/parking_complex'
require 'models/entry_point'
require 'models/small_parking_slot'
require 'models/medium_parking_slot'
require 'models/large_parking_slot'
require 'models/small_vehicle'
require 'models/medium_vehicle'
require 'models/large_vehicle'
require 'services/parking_allocator'
require 'services/fee_calculator'
require 'services/vehicle_tracker'
require 'repositories/in_memory_repository'

RSpec.describe ParkingComplex do
  describe 'initialization' do
    context 'with valid parameters' do
      let(:entry_points) { [EntryPoint.new(0), EntryPoint.new(1), EntryPoint.new(2)] }
      let(:parking_slots) do
        [
          SmallParkingSlot.new(1, [1, 4, 7]),
          SmallParkingSlot.new(2, [2, 3, 8]),
          MediumParkingSlot.new(3, [5, 1, 6]),
          MediumParkingSlot.new(4, [6, 2, 5]),
          LargeParkingSlot.new(5, [9, 5, 2]),
          LargeParkingSlot.new(6, [8, 6, 3])
        ]
      end

      it 'creates a parking complex with the given entry points and parking slots' do
        complex = ParkingComplex.new(entry_points, parking_slots)

        expect(complex.entry_points).to eq(entry_points)
        expect(complex.parking_slots).to eq(parking_slots)
      end

      it 'initializes with no parked vehicles' do
        complex = ParkingComplex.new(entry_points, parking_slots)

        expect(complex.parked_vehicles_count).to eq(0)
      end

      it 'accepts an optional repository' do
        repository = InMemoryRepository.new
        complex = ParkingComplex.new(entry_points, parking_slots, repository: repository)

        expect(complex.repository).to eq(repository)
      end

      it 'creates a default repository if none is provided' do
        complex = ParkingComplex.new(entry_points, parking_slots)

        expect(complex.repository).to be_a(InMemoryRepository)
      end

      it 'accepts an optional parking allocator' do
        allocator = ParkingAllocator.new
        complex = ParkingComplex.new(entry_points, parking_slots, allocator: allocator)

        expect(complex.allocator).to eq(allocator)
      end

      it 'creates a default parking allocator if none is provided' do
        complex = ParkingComplex.new(entry_points, parking_slots)

        expect(complex.allocator).to be_a(ParkingAllocator)
      end

      it 'accepts an optional fee calculator' do
        calculator = FeeCalculator.new
        complex = ParkingComplex.new(entry_points, parking_slots, calculator: calculator)

        expect(complex.calculator).to eq(calculator)
      end

      it 'creates a default fee calculator if none is provided' do
        complex = ParkingComplex.new(entry_points, parking_slots)

        expect(complex.calculator).to be_a(FeeCalculator)
      end

      it 'accepts an optional vehicle tracker' do
        tracker = VehicleTracker.new
        complex = ParkingComplex.new(entry_points, parking_slots, tracker: tracker)

        expect(complex.tracker).to eq(tracker)
      end

      it 'creates a default vehicle tracker if none is provided' do
        complex = ParkingComplex.new(entry_points, parking_slots)

        expect(complex.tracker).to be_a(VehicleTracker)
      end
    end

    context 'with invalid parameters' do
      let(:entry_points) { [EntryPoint.new(0), EntryPoint.new(1), EntryPoint.new(2)] }
      let(:parking_slots) do
        [
          SmallParkingSlot.new(1, [1, 4, 7]),
          MediumParkingSlot.new(2, [2, 3, 8]),
          LargeParkingSlot.new(3, [5, 1, 6])
        ]
      end

      it 'raises an error if entry points is nil' do
        expect { ParkingComplex.new(nil, parking_slots) }.to raise_error(ArgumentError)
      end

      it 'raises an error if entry points is empty' do
        expect { ParkingComplex.new([], parking_slots) }.to raise_error(ArgumentError)
      end

      it 'raises an error if there are fewer than 3 entry points' do
        few_entry_points = [EntryPoint.new(0), EntryPoint.new(1)]
        expect { ParkingComplex.new(few_entry_points, parking_slots) }.to raise_error(ArgumentError)
      end

      it 'raises an error if parking slots is nil' do
        expect { ParkingComplex.new(entry_points, nil) }.to raise_error(ArgumentError)
      end

      it 'raises an error if parking slots is empty' do
        expect { ParkingComplex.new(entry_points, []) }.to raise_error(ArgumentError)
      end

      it 'raises an error if any entry point is not an EntryPoint' do
        invalid_entry_points = [EntryPoint.new(0), 'not an entry point', EntryPoint.new(2)]
        expect { ParkingComplex.new(invalid_entry_points, parking_slots) }.to raise_error(ArgumentError)
      end

      it 'raises an error if any parking slot is not a ParkingSlot' do
        invalid_parking_slots = [SmallParkingSlot.new(1, [1, 4, 7]), 'not a parking slot', LargeParkingSlot.new(3, [5, 1, 6])]
        expect { ParkingComplex.new(entry_points, invalid_parking_slots) }.to raise_error(ArgumentError)
      end

      it 'raises an error if there are duplicate entry point IDs' do
        duplicate_entry_points = [EntryPoint.new(0), EntryPoint.new(1), EntryPoint.new(0)]
        expect { ParkingComplex.new(duplicate_entry_points, parking_slots) }.to raise_error(ArgumentError)
      end

      it 'raises an error if there are duplicate parking slot IDs' do
        duplicate_parking_slots = [
          SmallParkingSlot.new(1, [1, 4, 7]),
          MediumParkingSlot.new(1, [2, 3, 8]), # Duplicate ID
          LargeParkingSlot.new(3, [5, 1, 6])
        ]
        expect { ParkingComplex.new(entry_points, duplicate_parking_slots) }.to raise_error(ArgumentError)
      end

      it 'raises an error if parking slots have incorrect distance arrays' do
        mismatched_slots = [
          SmallParkingSlot.new(1, [1, 4]), # Only 2 distances for 3 entry points
          MediumParkingSlot.new(2, [2, 3, 8]),
          LargeParkingSlot.new(3, [5, 1, 6])
        ]
        expect { ParkingComplex.new(entry_points, mismatched_slots) }.to raise_error(ArgumentError)
      end
    end
  end

  describe 'entry point management' do
    let(:entry_points) { [EntryPoint.new(0), EntryPoint.new(1), EntryPoint.new(2)] }
    let(:parking_slots) do
      [
        SmallParkingSlot.new(1, [1, 4, 7]),
        MediumParkingSlot.new(2, [2, 3, 8]),
        LargeParkingSlot.new(3, [5, 1, 6])
      ]
    end
    let(:complex) { ParkingComplex.new(entry_points, parking_slots) }

    it 'provides access to entry points by ID' do
      expect(complex.get_entry_point(0)).to eq(entry_points[0])
      expect(complex.get_entry_point(1)).to eq(entry_points[1])
      expect(complex.get_entry_point(2)).to eq(entry_points[2])
    end

    it 'returns nil for non-existent entry point IDs' do
      expect(complex.get_entry_point(99)).to be_nil
    end

    it 'allows adding a new entry point' do
      new_entry_point = EntryPoint.new(3)

      # Add the new entry point
      complex.add_entry_point(new_entry_point)

      # Verify it was added
      expect(complex.entry_points).to include(new_entry_point)
      expect(complex.get_entry_point(3)).to eq(new_entry_point)
    end

    it 'raises an error when adding an entry point with duplicate ID' do
      duplicate_entry_point = EntryPoint.new(0)
      expect { complex.add_entry_point(duplicate_entry_point) }.to raise_error(ArgumentError)
    end

    it 'raises an error when adding an invalid entry point' do
      expect { complex.add_entry_point('not an entry point') }.to raise_error(ArgumentError)
    end
  end

  describe 'parking slot management' do
    let(:entry_points) { [EntryPoint.new(0), EntryPoint.new(1), EntryPoint.new(2)] }
    let(:parking_slots) do
      [
        SmallParkingSlot.new(1, [1, 4, 7]),
        MediumParkingSlot.new(2, [2, 3, 8]),
        LargeParkingSlot.new(3, [5, 1, 6])
      ]
    end
    let(:complex) { ParkingComplex.new(entry_points, parking_slots) }

    it 'provides access to parking slots by ID' do
      expect(complex.get_parking_slot(1)).to eq(parking_slots[0])
      expect(complex.get_parking_slot(2)).to eq(parking_slots[1])
      expect(complex.get_parking_slot(3)).to eq(parking_slots[2])
    end

    it 'returns nil for non-existent parking slot IDs' do
      expect(complex.get_parking_slot(99)).to be_nil
    end

    it 'provides access to all available parking slots' do
      available_slots = complex.available_parking_slots

      expect(available_slots.size).to eq(3) # All slots should be available initially
      expect(available_slots).to include(parking_slots[0], parking_slots[1], parking_slots[2])
    end

    it 'provides access to available parking slots by type' do
      small_slots = complex.available_parking_slots(type: :small)
      medium_slots = complex.available_parking_slots(type: :medium)
      large_slots = complex.available_parking_slots(type: :large)

      expect(small_slots.size).to eq(1)
      expect(small_slots).to include(parking_slots[0])

      expect(medium_slots.size).to eq(1)
      expect(medium_slots).to include(parking_slots[1])

      expect(large_slots.size).to eq(1)
      expect(large_slots).to include(parking_slots[2])
    end

    it 'allows adding a new parking slot' do
      new_slot = SmallParkingSlot.new(4, [3, 7, 9])

      # Add the new slot
      complex.add_parking_slot(new_slot)

      # Verify it was added
      expect(complex.parking_slots).to include(new_slot)
      expect(complex.get_parking_slot(4)).to eq(new_slot)
      expect(complex.available_parking_slots).to include(new_slot)
    end

    it 'raises an error when adding a parking slot with duplicate ID' do
      duplicate_slot = SmallParkingSlot.new(1, [3, 7, 9])
      expect { complex.add_parking_slot(duplicate_slot) }.to raise_error(ArgumentError)
    end

    it 'raises an error when adding an invalid parking slot' do
      expect { complex.add_parking_slot('not a parking slot') }.to raise_error(ArgumentError)
    end

    it 'raises an error when adding a parking slot with incorrect distances array' do
      invalid_slot = SmallParkingSlot.new(4, [3, 7]) # Only 2 distances for 3 entry points
      expect { complex.add_parking_slot(invalid_slot) }.to raise_error(ArgumentError)
    end
  end
end
