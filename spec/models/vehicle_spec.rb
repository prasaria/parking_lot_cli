require 'spec_helper'
require 'models/vehicle'

RSpec.describe Vehicle do
  # Test that Vehicle is an abstract class that can't be instantiated directly
  describe '.new' do
    it 'raises NotImplementedError when instantiated directly' do
      expect { Vehicle.new('ABC123', :small) }.to raise_error(NotImplementedError)
    end

    it 'allows subclasses to be instantiated' do
      # We need to create a concrete subclass for testing
      stub_const('ConcreteVehicle', Class.new(Vehicle) do
        def can_park_in?(_slot)
          true
        end
      end)

      expect { ConcreteVehicle.new('ABC123', :small) }.not_to raise_error
    end
  end

  # Test accessor methods for attributes
  describe 'attributes' do
    before do
      # Create a concrete subclass for testing the attributes
      stub_const('TestVehicle', Class.new(Vehicle) do
        def can_park_in?(_slot)
          true
        end
      end)

      @vehicle = TestVehicle.new('XYZ789', :medium)
    end

    it 'has a readable id' do
      expect(@vehicle.id).to eq('XYZ789')
    end

    it 'has a readable size' do
      expect(@vehicle.size).to eq(:medium)
    end

    it 'does not allow id to be changed' do
      expect { @vehicle.id = 'NEW123' }.to raise_error(NoMethodError)
    end

    it 'does not allow size to be changed' do
      expect { @vehicle.size = :large }.to raise_error(NoMethodError)
    end
  end

  # Test that abstract methods raise NotImplementedError
  describe '#can_park_in?' do
    it "raises NotImplementedError when called directly from a subclass that doesn't implement it" do
      # Create a subclass that doesn't implement can_park_in?
      stub_const('IncompleteVehicle', Class.new(Vehicle))

      incomplete_vehicle = nil

      # First verify we can instantiate it (because it's a subclass)
      expect { incomplete_vehicle = IncompleteVehicle.new('ABC123', :small) }.not_to raise_error

      # Then verify the abstract method raises NotImplementedError
      expect { incomplete_vehicle.can_park_in?(double('slot')) }.to raise_error(NotImplementedError)
    end
  end

  # Test equality behavior
  describe 'equality' do
    before do
      stub_const('TestVehicle', Class.new(Vehicle) do
        def can_park_in?(_slot)
          true
        end
      end)
    end

    it 'considers two vehicles with the same ID to be equal' do
      vehicle1 = TestVehicle.new('SAME123', :small)
      vehicle2 = TestVehicle.new('SAME123', :small)

      expect(vehicle1).to eq(vehicle2)
    end

    it 'considers two vehicles with different IDs to be different' do
      vehicle1 = TestVehicle.new('ID1', :small)
      vehicle2 = TestVehicle.new('ID2', :small)

      expect(vehicle1).not_to eq(vehicle2)
    end

    it 'considers vehicles and other objects to be different' do
      vehicle = TestVehicle.new('ID1', :small)

      expect(vehicle).not_to eq('not a vehicle')
    end
  end
end
