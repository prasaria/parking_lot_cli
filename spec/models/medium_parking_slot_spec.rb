# frozen_string_literal: true

require 'spec_helper'
require 'models/medium_parking_slot'
require 'models/small_vehicle'
require 'models/medium_vehicle'
require 'models/large_vehicle'

RSpec.describe MediumParkingSlot do
  let(:slot_id) { 2 }
  let(:distances) { [4, 2, 6] } # Distances from 3 entry points
  let(:slot) { MediumParkingSlot.new(slot_id, distances) }

  describe '.new' do
    it 'creates a new medium parking slot with the given id and distances' do
      expect(slot.id).to eq(slot_id)
      expect(slot.distances).to eq(distances)
    end

    it 'sets the size to :medium' do
      expect(slot.size).to eq(:medium)
    end
  end

  describe '#can_fit?' do
    let(:small_vehicle) { SmallVehicle.new('S-123') }
    let(:medium_vehicle) { MediumVehicle.new('M-456') }
    let(:large_vehicle) { LargeVehicle.new('L-789') }

    it 'can fit a small vehicle' do
      expect(slot.can_fit?(small_vehicle)).to be true
    end

    it 'can fit a medium vehicle' do
      expect(slot.can_fit?(medium_vehicle)).to be true
    end

    it 'cannot fit a large vehicle' do
      expect(slot.can_fit?(large_vehicle)).to be false
    end

    it 'raises an error when vehicle is nil' do
      expect { slot.can_fit?(nil) }.to raise_error(NoMethodError)
    end
  end

  describe 'compatibility with requirements' do
    it 'follows the rule that medium slots can fit small and medium vehicles' do
      small_vehicle = SmallVehicle.new('S-123')
      medium_vehicle = MediumVehicle.new('M-456')
      large_vehicle = LargeVehicle.new('L-789')

      # Medium slots should fit small and medium vehicles, but not large ones
      expect(slot.can_fit?(small_vehicle)).to be true
      expect(slot.can_fit?(medium_vehicle)).to be true
      expect(slot.can_fit?(large_vehicle)).to be false
    end
  end

  describe 'inheritance' do
    it 'is a subclass of ParkingSlot' do
      expect(MediumParkingSlot.superclass).to eq(ParkingSlot)
    end
  end

  describe 'availability' do
    it 'is available when created' do
      expect(slot.available?).to be true
    end

    it 'becomes unavailable when occupied' do
      slot.occupy
      expect(slot.available?).to be false
    end

    it 'becomes available again when vacated' do
      slot.occupy
      slot.vacate
      expect(slot.available?).to be true
    end
  end

  describe 'distance calculation' do
    it 'calculates distance from an entry point correctly' do
      entry_point = double('EntryPoint', id: 1)
      expect(slot.distance_from(entry_point)).to eq(distances[1])
    end
  end

  describe 'validation' do
    it 'validates the format of distances' do
      expect { MediumParkingSlot.new(slot_id, 'not an array') }.to raise_error(ArgumentError)
      expect { MediumParkingSlot.new(slot_id, []) }.to raise_error(ArgumentError)
      expect { MediumParkingSlot.new(slot_id, [1, 'two', 3]) }.to raise_error(ArgumentError)
    end
  end
end
