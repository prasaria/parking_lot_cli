# frozen_string_literal: true

require 'spec_helper'
require 'models/medium_vehicle'

RSpec.describe MediumVehicle do
  let(:license_plate) { 'MED456' }
  let(:vehicle) { MediumVehicle.new(license_plate) }

  describe '.new' do
    it 'creates a new medium vehicle with the given id' do
      expect(vehicle.id).to eq(license_plate)
    end

    it 'sets the size to :medium' do
      expect(vehicle.size).to eq(:medium)
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

    it 'can park in a medium parking slot' do
      expect(vehicle.can_park_in?(medium_slot)).to be true
    end

    it 'can park in a large parking slot' do
      expect(vehicle.can_park_in?(large_slot)).to be true
    end
  end

  describe 'inheritance' do
    it 'is a subclass of Vehicle' do
      expect(MediumVehicle.superclass).to eq(Vehicle)
    end
  end

  describe 'equality' do
    it 'considers two medium vehicles with the same license plate as equal' do
      vehicle1 = MediumVehicle.new('SAME456')
      vehicle2 = MediumVehicle.new('SAME456')

      expect(vehicle1).to eq(vehicle2)
    end

    it 'considers two medium vehicles with different license plates as different' do
      vehicle1 = MediumVehicle.new('MED123')
      vehicle2 = MediumVehicle.new('MED789')

      expect(vehicle1).not_to eq(vehicle2)
    end

    it 'considers vehicles of different types with the same license plate as equal' do
      medium_vehicle = MediumVehicle.new('SAME123')
      small_vehicle = SmallVehicle.new('SAME123')

      expect(medium_vehicle).to eq(small_vehicle)
    end
  end

  describe 'compatibility with requirements' do
    it 'follows the rule that medium vehicles can only park in medium and large slots' do
      # This test ensures that the implementation follows the business requirements
      small_slot = double('SmallParkingSlot', size: :small)
      medium_slot = double('MediumParkingSlot', size: :medium)
      large_slot = double('LargeParkingSlot', size: :large)

      # Medium vehicles should only be able to park in medium and large slots
      expect(vehicle.can_park_in?(small_slot)).to be false
      expect(vehicle.can_park_in?(medium_slot)).to be true
      expect(vehicle.can_park_in?(large_slot)).to be true
    end
  end
end
