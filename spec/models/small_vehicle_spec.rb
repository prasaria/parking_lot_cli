# frozen_string_literal: true

require 'spec_helper'
require 'models/small_vehicle'
require 'models/parking_slot' # We'll need this for testing can_park_in?

RSpec.describe SmallVehicle do
  let(:license_plate) { 'ABC123' }
  let(:vehicle) { SmallVehicle.new(license_plate) }

  describe '.new' do
    it 'creates a new small vehicle with the given id' do
      expect(vehicle.id).to eq(license_plate)
    end

    it 'sets the size to :small' do
      expect(vehicle.size).to eq(:small)
    end
  end

  describe '#can_park_in?' do
    # Create mock parking slots for testing compatibility
    # We'll use doubles here since the actual ParkingSlot classes haven't been implemented yet
    let(:small_slot) { double('SmallParkingSlot', size: :small) }
    let(:medium_slot) { double('MediumParkingSlot', size: :medium) }
    let(:large_slot) { double('LargeParkingSlot', size: :large) }

    it 'can park in a small parking slot' do
      expect(vehicle.can_park_in?(small_slot)).to be true
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
      expect(SmallVehicle.superclass).to eq(Vehicle)
    end
  end

  describe 'equality' do
    it 'considers two small vehicles with the same license plate as equal' do
      vehicle1 = SmallVehicle.new('SAME456')
      vehicle2 = SmallVehicle.new('SAME456')

      expect(vehicle1).to eq(vehicle2)
    end

    it 'considers two small vehicles with different license plates as different' do
      vehicle1 = SmallVehicle.new('ABC123')
      vehicle2 = SmallVehicle.new('XYZ789')

      expect(vehicle1).not_to eq(vehicle2)
    end

    # Test that equality works across different vehicle types (inherited from Vehicle)
    it 'considers vehicles of different types with the same license plate as equal' do
      # We'll need to create a test subclass for a different vehicle type
      stub_const('TestMediumVehicle', Class.new(Vehicle) do
        def initialize(id)
          super(id, :medium)
        end

        def can_park_in?(_slot)
          true
        end
      end)

      small_vehicle = SmallVehicle.new('SAME123')
      medium_vehicle = TestMediumVehicle.new('SAME123')

      expect(small_vehicle).to eq(medium_vehicle)
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
