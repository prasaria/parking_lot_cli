# frozen_string_literal: true

require 'spec_helper'
require 'services/parking_allocator'
require 'models/small_vehicle'
require 'models/medium_vehicle'
require 'models/large_vehicle'
require 'models/small_parking_slot'
require 'models/medium_parking_slot'
require 'models/large_parking_slot'
require 'models/entry_point'

RSpec.describe ParkingAllocator do
  let(:entry_point) { EntryPoint.new(0) }
  let(:allocator) { ParkingAllocator.new }

  describe '#find_slot' do
    context 'with no available slots' do
      it 'returns nil' do
        expect(allocator.find_slot(SmallVehicle.new('S123'), [], entry_point)).to be_nil
      end
    end

    context 'with no compatible slots' do
      let(:large_vehicle) { LargeVehicle.new('L123') }
      let(:small_slot) { SmallParkingSlot.new(1, [3, 5, 7]) }
      let(:medium_slot) { MediumParkingSlot.new(2, [4, 2, 6]) }
      let(:slots) { [small_slot, medium_slot] }

      it 'returns nil for a large vehicle with only small and medium slots' do
        expect(allocator.find_slot(large_vehicle, slots, entry_point)).to be_nil
      end
    end

    context 'with one compatible slot' do
      let(:small_vehicle) { SmallVehicle.new('S123') }
      let(:small_slot) { SmallParkingSlot.new(1, [3, 5, 7]) }
      let(:slots) { [small_slot] }

      it 'returns the only compatible slot' do
        expect(allocator.find_slot(small_vehicle, slots, entry_point)).to eq(small_slot)
      end
    end

    context 'with multiple compatible slots' do
      let(:small_vehicle) { SmallVehicle.new('S123') }
      let(:slot1) { SmallParkingSlot.new(1, [3, 5, 7]) } # Distance 3 from entry point 0
      let(:slot2) { SmallParkingSlot.new(2, [1, 6, 8]) } # Distance 1 from entry point 0
      let(:slot3) { SmallParkingSlot.new(3, [5, 2, 4]) } # Distance 5 from entry point 0
      let(:slots) { [slot1, slot2, slot3] }

      it 'returns the closest compatible slot' do
        expect(allocator.find_slot(small_vehicle, slots, entry_point)).to eq(slot2)
      end
    end

    context 'with multiple compatible slots at the same distance' do
      let(:small_vehicle) { SmallVehicle.new('S123') }
      let(:slot1) { SmallParkingSlot.new(1, [3, 5, 7]) } # Distance 3 from entry point 0
      let(:slot2) { SmallParkingSlot.new(2, [3, 6, 8]) } # Also distance 3 from entry point 0
      let(:slots) { [slot1, slot2] }

      it 'returns the first slot found (based on slot ID)' do
        expect(allocator.find_slot(small_vehicle, slots, entry_point)).to eq(slot1)
      end
    end

    context 'with different entry points' do
      let(:entry_point1) { EntryPoint.new(1) }
      let(:small_vehicle) { SmallVehicle.new('S123') }
      let(:slot1) { SmallParkingSlot.new(1, [3, 5, 7]) } # Distance 5 from entry point 1
      let(:slot2) { SmallParkingSlot.new(2, [6, 2, 8]) } # Distance 2 from entry point 1
      let(:slots) { [slot1, slot2] }

      it 'uses the correct distance for the specified entry point' do
        expect(allocator.find_slot(small_vehicle, slots, entry_point1)).to eq(slot2)
      end
    end

    context 'with a mix of vehicle and slot types' do
      let(:small_vehicle) { SmallVehicle.new('S123') }
      let(:medium_vehicle) { MediumVehicle.new('M456') }
      let(:large_vehicle) { LargeVehicle.new('L789') }

      let(:small_slot_close) { SmallParkingSlot.new(1, [1, 5, 7]) }   # Distance 1
      let(:medium_slot_far) { MediumParkingSlot.new(2, [10, 12, 8]) } # Distance 10
      let(:large_slot_medium) { LargeParkingSlot.new(3, [5, 3, 4]) }  # Distance 5
      let(:slots) { [small_slot_close, medium_slot_far, large_slot_medium] }

      it 'finds the closest compatible slot for a small vehicle' do
        expect(allocator.find_slot(small_vehicle, slots, entry_point)).to eq(small_slot_close)
      end

      it 'finds the closest compatible slot for a medium vehicle' do
        # Medium vehicles can park in medium or large slots
        expect(allocator.find_slot(medium_vehicle, slots, entry_point)).to eq(large_slot_medium)
      end

      it 'finds the closest compatible slot for a large vehicle' do
        # Large vehicles can only park in large slots
        expect(allocator.find_slot(large_vehicle, slots, entry_point)).to eq(large_slot_medium)
      end
    end

    context 'with unavailable slots' do
      let(:small_vehicle) { SmallVehicle.new('S123') }
      let(:available_slot) { SmallParkingSlot.new(1, [3, 5, 7]) }
      let(:unavailable_slot) { SmallParkingSlot.new(2, [1, 6, 8]) } # Closer but unavailable
      let(:slots) { [available_slot, unavailable_slot] }

      before do
        unavailable_slot.occupy
      end

      it 'only considers available slots' do
        expect(allocator.find_slot(small_vehicle, slots, entry_point)).to eq(available_slot)
      end
    end

    context 'with invalid inputs' do
      let(:small_vehicle) { SmallVehicle.new('S123') }
      let(:slots) { [SmallParkingSlot.new(1, [3, 5, 7])] }

      it 'raises an error if vehicle is nil' do
        expect { allocator.find_slot(nil, slots, entry_point) }.to raise_error(ArgumentError)
      end

      it 'raises an error if slots is nil' do
        expect do
          allocator.find_slot(small_vehicle, nil, entry_point)
        end.to raise_error(ArgumentError)
      end

      it 'raises an error if entry point is nil' do
        expect { allocator.find_slot(small_vehicle, slots, nil) }.to raise_error(ArgumentError)
      end
    end
  end
end
