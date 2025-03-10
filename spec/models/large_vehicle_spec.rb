# frozen_string_literal: true

require 'spec_helper'
require 'models/large_vehicle'
require 'models/small_vehicle'

RSpec.describe LargeVehicle do
  let(:license_plate) { 'LRG789' }
  let(:vehicle) { LargeVehicle.new(license_plate) }

  describe '.new' do
    it 'creates a new large vehicle with the given id' do
      expect(vehicle.id).to eq(license_plate)
    end

    it 'sets the size to :large' do
      expect(vehicle.size).to eq(:large)
    end
  end

  describe '#can_park_in?' do
    # Create mock parking slots for testing compatibility
    let(:small_slot) { double('SmallParkingSlot', size: :small) }
    let(:medium_slot) { double('MediumParkingSlot', size: :medium) }
    let(:large_slot) { double('LargeParkingSlot', size: :large) }

    it 'cannot park in a small parking slot' do
      expect(vehicle.can_park_in?(small_slot)).to be false
    end

    it 'cannot park in a medium parking slot' do
      expect(vehicle.can_park_in?(medium_slot)).to be false
    end

    it 'can park in a large parking slot' do
      expect(vehicle.can_park_in?(large_slot)).to be true
    end
  end

  describe 'inheritance' do
    it 'is a subclass of Vehicle' do
      expect(LargeVehicle.superclass).to eq(Vehicle)
    end
  end

  describe 'equality' do
    it 'considers two large vehicles with the same license plate as equal' do
      vehicle1 = LargeVehicle.new('SAME789')
      vehicle2 = LargeVehicle.new('SAME789')

      expect(vehicle1).to eq(vehicle2)
    end

    it 'considers two large vehicles with different license plates as different' do
      vehicle1 = LargeVehicle.new('LRG123')
      vehicle2 = LargeVehicle.new('LRG456')

      expect(vehicle1).not_to eq(vehicle2)
    end

    it 'considers vehicles of different types with the same license plate as equal' do
      large_vehicle = LargeVehicle.new('SAME123')
      small_vehicle = SmallVehicle.new('SAME123')

      expect(large_vehicle).to eq(small_vehicle)
    end
  end

  describe 'compatibility with requirements' do
    it 'follows the rule that large vehicles can only park in large slots' do
      # This test ensures that the implementation follows the business requirements
      small_slot = double('SmallParkingSlot', size: :small)
      medium_slot = double('MediumParkingSlot', size: :medium)
      large_slot = double('LargeParkingSlot', size: :large)

      # Large vehicles should only be able to park in large slots
      expect(vehicle.can_park_in?(small_slot)).to be false
      expect(vehicle.can_park_in?(medium_slot)).to be false
      expect(vehicle.can_park_in?(large_slot)).to be true
    end
  end

  describe 'behavior with invalid input' do
    it 'handles nil slot gracefully' do
      expect { vehicle.can_park_in?(nil) }.to raise_error(NoMethodError)
    end

    it 'handles slot with missing size property' do
      # Create a double that will raise NoMethodError when size is called
      invalid_slot = double('InvalidSlot')
      allow(invalid_slot).to receive(:size).and_raise(NoMethodError)

      expect { vehicle.can_park_in?(invalid_slot) }.to raise_error(NoMethodError)
    end
  end
end
