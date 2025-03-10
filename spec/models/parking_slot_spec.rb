# frozen_string_literal: true

require 'spec_helper'
require 'models/parking_slot'
require 'models/entry_point'

RSpec.describe ParkingSlot do
  let(:slot_id) { 1 }
  let(:distances) { [3, 5, 7] } # Distances from 3 entry points

  describe 'initialization' do
    it 'raises NotImplementedError when instantiated directly' do
      expect { ParkingSlot.new(slot_id, :small, distances) }.to raise_error(NotImplementedError)
    end

    it 'allows subclasses to be instantiated' do
      # Create a concrete subclass for testing
      stub_const('TestSlot', Class.new(ParkingSlot) do
        def can_fit?(_vehicle)
          true
        end
      end)

      expect { TestSlot.new(slot_id, :small, distances) }.not_to raise_error
    end
  end

  describe 'attributes' do
    before do
      # Create a concrete subclass for testing attributes
      stub_const('TestSlot', Class.new(ParkingSlot) do
        def can_fit?(_vehicle)
          true
        end
      end)

      @slot = TestSlot.new(slot_id, :small, distances)
    end

    it 'has a readable id' do
      expect(@slot.id).to eq(slot_id)
    end

    it 'has a readable size' do
      expect(@slot.size).to eq(:small)
    end

    it 'has readable distances' do
      expect(@slot.distances).to eq(distances)
    end

    it 'does not allow id to be changed' do
      expect { @slot.id = 2 }.to raise_error(NoMethodError)
    end

    it 'does not allow size to be changed' do
      expect { @slot.size = :medium }.to raise_error(NoMethodError)
    end

    it 'does not allow distances to be changed' do
      expect { @slot.distances = [1, 2, 3] }.to raise_error(NoMethodError)
    end

    it 'initializes as available' do
      expect(@slot.available?).to be true
    end
  end

  describe '#distance_from' do
    before do
      stub_const('TestSlot', Class.new(ParkingSlot) do
        def can_fit?(_vehicle)
          true
        end
      end)

      @slot = TestSlot.new(slot_id, :small, distances)
    end

    it 'returns the distance from a specific entry point' do
      entry_point = double('EntryPoint')
      allow(entry_point).to receive(:id).and_return(0)

      expect(@slot.distance_from(entry_point)).to eq(distances[0])
    end

    it 'returns the distance from another entry point' do
      entry_point = double('EntryPoint')
      allow(entry_point).to receive(:id).and_return(1)

      expect(@slot.distance_from(entry_point)).to eq(distances[1])
    end

    it 'raises an error if entry point ID is out of range' do
      entry_point = double('EntryPoint')
      allow(entry_point).to receive(:id).and_return(10)

      expect { @slot.distance_from(entry_point) }.to raise_error(IndexError)
    end

    it 'raises an error if entry point is nil' do
      expect { @slot.distance_from(nil) }.to raise_error(NoMethodError)
    end
  end

  describe '#occupy and #vacate' do
    before do
      stub_const('TestSlot', Class.new(ParkingSlot) do
        def can_fit?(_vehicle)
          true
        end
      end)

      @slot = TestSlot.new(slot_id, :small, distances)
    end

    it 'marks the slot as unavailable when occupied' do
      @slot.occupy
      expect(@slot.available?).to be false
    end

    it 'marks the slot as available when vacated' do
      @slot.occupy
      @slot.vacate
      expect(@slot.available?).to be true
    end

    it 'can be occupied multiple times after vacating' do
      @slot.occupy
      @slot.vacate
      @slot.occupy
      expect(@slot.available?).to be false
    end
  end

  describe '#can_fit?' do
    it 'raises NotImplementedError when called directly from a subclass that doesn\'t implement it' do
      # Create a subclass that doesn't implement can_fit?
      stub_const('IncompleteSlot', Class.new(ParkingSlot))

      incomplete_slot = nil

      # First verify we can instantiate it (because it's a subclass)
      expect { incomplete_slot = IncompleteSlot.new(slot_id, :small, distances) }.not_to raise_error

      # Then verify the abstract method raises NotImplementedError
      expect { incomplete_slot.can_fit?(double('vehicle')) }.to raise_error(NotImplementedError)
    end
  end

  describe 'equality' do
    before do
      stub_const('TestSlot', Class.new(ParkingSlot) do
        def can_fit?(_vehicle)
          true
        end
      end)
    end

    it 'considers two slots with the same ID to be equal' do
      slot1 = TestSlot.new(1, :small, [1, 2, 3])
      slot2 = TestSlot.new(1, :medium, [4, 5, 6]) # Different size and distances

      expect(slot1).to eq(slot2)
    end

    it 'considers two slots with different IDs to be different' do
      slot1 = TestSlot.new(1, :small, [1, 2, 3])
      slot2 = TestSlot.new(2, :small, [1, 2, 3]) # Same size and distances

      expect(slot1).not_to eq(slot2)
    end

    it 'considers slots and other objects to be different' do
      slot = TestSlot.new(1, :small, [1, 2, 3])

      expect(slot).not_to eq('not a slot')
    end
  end

  describe 'validation' do
    before do
      stub_const('TestSlot', Class.new(ParkingSlot) do
        def can_fit?(_vehicle)
          true
        end
      end)
    end

    it 'rejects invalid sizes' do
      expect { TestSlot.new(1, :unknown_size, [1, 2, 3]) }.to raise_error(ArgumentError)
    end

    it 'requires distances to be an array' do
      expect { TestSlot.new(1, :small, 'not an array') }.to raise_error(ArgumentError)
    end

    it 'requires distances array to not be empty' do
      expect { TestSlot.new(1, :small, []) }.to raise_error(ArgumentError)
    end

    it 'requires distances to be numeric' do
      expect { TestSlot.new(1, :small, [1, 'two', 3]) }.to raise_error(ArgumentError)
    end
  end
end
