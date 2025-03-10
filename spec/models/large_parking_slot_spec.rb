# frozen_string_literal: true

require 'spec_helper'
require 'models/large_parking_slot'
require 'models/small_vehicle'
require 'models/medium_vehicle'
require 'models/large_vehicle'

RSpec.describe LargeParkingSlot do
  let(:slot_id) { 3 }
  let(:distances) { [6, 8, 2] } # Distances from 3 entry points
  let(:slot) { LargeParkingSlot.new(slot_id, distances) }

  describe '.new' do
    it 'creates a new large parking slot with the given id and distances' do
      expect(slot.id).to eq(slot_id)
      expect(slot.distances).to eq(distances)
    end

    it 'sets the size to :large' do
      expect(slot.size).to eq(:large)
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

    it 'can fit a large vehicle' do
      expect(slot.can_fit?(large_vehicle)).to be true
    end

    it 'raises an error when vehicle is nil' do
      expect { slot.can_fit?(nil) }.to raise_error(NoMethodError)
    end
  end

  describe 'compatibility with requirements' do
    it 'follows the rule that large slots can fit any vehicle type' do
      small_vehicle = SmallVehicle.new('S-123')
      medium_vehicle = MediumVehicle.new('M-456')
      large_vehicle = LargeVehicle.new('L-789')

      # Large slots should fit all vehicle types
      expect(slot.can_fit?(small_vehicle)).to be true
      expect(slot.can_fit?(medium_vehicle)).to be true
      expect(slot.can_fit?(large_vehicle)).to be true
    end
  end

  describe 'inheritance' do
    it 'is a subclass of ParkingSlot' do
      expect(LargeParkingSlot.superclass).to eq(ParkingSlot)
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
      expect { LargeParkingSlot.new(slot_id, 'not an array') }.to raise_error(ArgumentError)
      expect { LargeParkingSlot.new(slot_id, []) }.to raise_error(ArgumentError)
      expect { LargeParkingSlot.new(slot_id, [1, 'two', 3]) }.to raise_error(ArgumentError)
    end
  end
end
