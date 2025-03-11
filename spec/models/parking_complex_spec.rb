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

  describe 'park operation' do
    let(:entry_points) { [EntryPoint.new(0), EntryPoint.new(1), EntryPoint.new(2)] }
    let(:parking_slots) do
      [
        SmallParkingSlot.new(1, [1, 4, 7]),
        MediumParkingSlot.new(2, [2, 3, 8]),
        LargeParkingSlot.new(3, [5, 1, 6])
      ]
    end
    let(:complex) { ParkingComplex.new(entry_points, parking_slots) }

    describe '#park' do
      context 'with a small vehicle' do
        let(:small_vehicle) { SmallVehicle.new('SV001') }

        it 'assigns the closest available compatible slot' do
          # Entry point 0 has distances [1, 2, 5] to the slots
          # The small slot (id=1) is closest with distance 1
          ticket = complex.park(small_vehicle, entry_points[0])

          expect(ticket).not_to be_nil
          expect(ticket.vehicle).to eq(small_vehicle)
          expect(ticket.slot).to eq(parking_slots[0]) # The small slot
          expect(ticket.entry_point).to eq(entry_points[0])
          expect(ticket.exit_time).to be_nil
        end

        it 'marks the assigned slot as unavailable' do
          complex.park(small_vehicle, entry_points[0])

          # The small slot should now be unavailable
          expect(parking_slots[0].available?).to be false

          # Other slots should still be available
          expect(parking_slots[1].available?).to be true
          expect(parking_slots[2].available?).to be true
        end

        it 'increases the parked vehicles count' do
          expect do
            complex.park(small_vehicle, entry_points[0])
          end.to change { complex.parked_vehicles_count }.by(1)
        end

        it 'tracks the parked vehicle' do
          ticket = complex.park(small_vehicle, entry_points[0])

          expect(complex.tracker.currently_parked?(small_vehicle)).to be true
          expect(complex.tracker.get_active_ticket(small_vehicle)).to eq(ticket)
        end

        it 'selects a different slot if the closest is occupied' do
          # Park a vehicle in the small slot first
          another_vehicle = SmallVehicle.new('SV002')
          complex.park(another_vehicle, entry_points[0])

          # Now park our test vehicle - it should get the medium slot (next closest compatible slot)
          ticket = complex.park(small_vehicle, entry_points[0])

          expect(ticket.slot).to eq(parking_slots[1]) # The medium slot
        end

        it 'returns nil if no compatible slot is available' do
          # Park vehicles in all slots
          complex.park(SmallVehicle.new('SV002'), entry_points[0])
          complex.park(MediumVehicle.new('MV001'), entry_points[0])
          complex.park(LargeVehicle.new('LV001'), entry_points[0])

          # Try to park another vehicle
          ticket = complex.park(small_vehicle, entry_points[0])

          expect(ticket).to be_nil
        end
      end

      context 'with a medium vehicle' do
        let(:medium_vehicle) { MediumVehicle.new('MV001') }

        it 'assigns a medium or large slot' do
          # Entry point 0 has distances [2, 5] to the medium and large slots
          # The medium slot (id=2) is closest with distance 2
          ticket = complex.park(medium_vehicle, entry_points[0])

          expect(ticket).not_to be_nil
          expect(ticket.vehicle).to eq(medium_vehicle)
          expect(ticket.slot).to eq(parking_slots[1]) # The medium slot
        end

        it 'does not assign a small slot' do
          # Make the medium and large slots unavailable
          parking_slots[1].occupy
          parking_slots[2].occupy

          # Try to park a medium vehicle
          ticket = complex.park(medium_vehicle, entry_points[0])

          # Should not get a ticket since no compatible slot is available
          expect(ticket).to be_nil

          # The small slot should still be available
          expect(parking_slots[0].available?).to be true
        end
      end

      context 'with a large vehicle' do
        let(:large_vehicle) { LargeVehicle.new('LV001') }

        it 'assigns only a large slot' do
          # Entry point 0 has distance 5 to the large slot
          ticket = complex.park(large_vehicle, entry_points[0])

          expect(ticket).not_to be_nil
          expect(ticket.vehicle).to eq(large_vehicle)
          expect(ticket.slot).to eq(parking_slots[2]) # The large slot
        end

        it 'does not assign a small or medium slot' do
          # Make the large slot unavailable
          parking_slots[2].occupy

          # Try to park a large vehicle
          ticket = complex.park(large_vehicle, entry_points[0])

          # Should not get a ticket since no compatible slot is available
          expect(ticket).to be_nil

          # The small and medium slots should still be available
          expect(parking_slots[0].available?).to be true
          expect(parking_slots[1].available?).to be true
        end
      end

      context 'with different entry points' do
        let(:small_vehicle) { SmallVehicle.new('SV001') }

        it 'assigns the closest slot based on the entry point' do
          # Entry point 1 has distances [4, 3, 1] to the slots
          # The large slot (id=3) is closest with distance 1
          ticket = complex.park(small_vehicle, entry_points[1])

          expect(ticket.slot).to eq(parking_slots[2]) # The large slot

          # Entry point 2 has distances [7, 8, 6] to the slots
          # The large slot (id=3) is closest with distance 6
          another_vehicle = SmallVehicle.new('SV002')
          ticket = complex.park(another_vehicle, entry_points[2])

          # The large slot is now occupied, so it should get the small slot (distance 7)
          expect(ticket.slot).to eq(parking_slots[0]) # The small slot
        end
      end

      context 'with error conditions' do
        let(:small_vehicle) { SmallVehicle.new('SV001') }

        it 'raises an error if the vehicle is nil' do
          expect { complex.park(nil, entry_points[0]) }.to raise_error(ArgumentError)
        end

        it 'raises an error if the entry point is nil' do
          expect { complex.park(small_vehicle, nil) }.to raise_error(ArgumentError)
        end

        it 'raises an error if the entry point is invalid' do
          invalid_entry_point = 'not an entry point'
          expect { complex.park(small_vehicle, invalid_entry_point) }.to raise_error(ArgumentError)
        end

        it 'raises an error if the vehicle is already parked' do
          # Park the vehicle once
          complex.park(small_vehicle, entry_points[0])

          # Try to park it again
          expect { complex.park(small_vehicle, entry_points[0]) }.to raise_error(ArgumentError)
        end
      end

      context 'with continuous rate scenario' do
        let(:small_vehicle) { SmallVehicle.new('SV001') }

        it 'applies continuous rate for vehicle returning within 1 hour' do
          # Park the vehicle
          first_ticket = complex.park(small_vehicle, entry_points[0])

          # Unpark the vehicle
          exit_time = Time.now + (2 * 3600) # 2 hours later
          complex.unpark(small_vehicle, exit_time)

          # Park the vehicle again within 1 hour
          return_time = exit_time + (30 * 60) # 30 minutes after exit
          allow(Time).to receive(:now).and_return(return_time)

          second_ticket = complex.park(small_vehicle, entry_points[0])

          # The second ticket should reference the first ticket for continuous rate
          expect(second_ticket.previous_ticket).to eq(first_ticket)
        end

        it 'does not apply continuous rate for vehicle returning after 1 hour' do
          # Park the vehicle
          _first_ticket = complex.park(small_vehicle, entry_points[0])

          # Unpark the vehicle
          exit_time = Time.now + (2 * 3600) # 2 hours later
          complex.unpark(small_vehicle, exit_time)

          # Park the vehicle again after more than 1 hour
          return_time = exit_time + (65 * 60) # 65 minutes after exit
          allow(Time).to receive(:now).and_return(return_time)

          second_ticket = complex.park(small_vehicle, entry_points[0])

          # The second ticket should not reference the first ticket
          expect(second_ticket.previous_ticket).to be_nil
        end
      end
    end
  end
end
