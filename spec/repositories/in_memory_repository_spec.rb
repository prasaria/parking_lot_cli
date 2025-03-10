# frozen_string_literal: true

require 'spec_helper'
require 'repositories/in_memory_repository'
require 'models/small_vehicle'
require 'models/medium_vehicle'
require 'models/small_parking_slot'
require 'models/entry_point'

RSpec.describe InMemoryRepository do
  describe 'initialization' do
    it 'creates an empty repository' do
      repo = InMemoryRepository.new
      expect(repo.empty?).to be true
    end
  end

  describe 'basic functionality' do
    let(:repo) { InMemoryRepository.new }
    let(:vehicle) { SmallVehicle.new('ABC123') }
    let(:slot) { SmallParkingSlot.new(1, [3, 5, 7]) }
    let(:entry_point) { EntryPoint.new(0) }

    describe '#add' do
      it 'adds an object to the repository' do
        expect(repo.add(vehicle)).to eq(vehicle)
        expect(repo.empty?).to be false
      end

      it 'adds different types of objects' do
        expect(repo.add(vehicle)).to eq(vehicle)
        expect(repo.add(slot)).to eq(slot)
        expect(repo.add(entry_point)).to eq(entry_point)
      end

      it 'raises an error when adding nil' do
        expect { repo.add(nil) }.to raise_error(ArgumentError)
      end

      it 'raises an error when adding an object without an id' do
        object_without_id = Object.new
        expect { repo.add(object_without_id) }.to raise_error(ArgumentError)
      end
    end

    describe '#find' do
      before do
        repo.add(vehicle)
        repo.add(slot)
        repo.add(entry_point)
      end

      it 'finds an object by type and id' do
        expect(repo.find(SmallVehicle, 'ABC123')).to eq(vehicle)
        expect(repo.find(SmallParkingSlot, 1)).to eq(slot)
        expect(repo.find(EntryPoint, 0)).to eq(entry_point)
      end

      it 'returns nil when object is not found' do
        expect(repo.find(SmallVehicle, 'XYZ789')).to be_nil
        expect(repo.find(SmallParkingSlot, 999)).to be_nil
      end

      it 'raises an error when type is nil' do
        expect { repo.find(nil, 'ABC123') }.to raise_error(ArgumentError)
      end
    end

    describe '#all' do
      before do
        repo.add(vehicle)
        repo.add(SmallVehicle.new('XYZ789'))
        repo.add(slot)
        repo.add(entry_point)
      end

      it 'returns all objects of a given type' do
        expect(repo.all(SmallVehicle).size).to eq(2)
        expect(repo.all(SmallParkingSlot).size).to eq(1)
        expect(repo.all(EntryPoint).size).to eq(1)
      end

      it 'returns an empty array when no objects of the type exist' do
        expect(repo.all(MediumVehicle)).to eq([])
      end

      it 'raises an error when type is nil' do
        expect { repo.all(nil) }.to raise_error(ArgumentError)
      end
    end

    describe '#remove' do
      before do
        repo.add(vehicle)
        repo.add(slot)
      end

      it 'removes an object from the repository' do
        expect(repo.remove(vehicle)).to eq(vehicle)
        expect(repo.find(SmallVehicle, 'ABC123')).to be_nil
      end

      it 'returns nil when trying to remove an object that does not exist' do
        non_existent_vehicle = SmallVehicle.new('NONEXISTENT')
        expect(repo.remove(non_existent_vehicle)).to be_nil
      end

      it 'raises an error when trying to remove nil' do
        expect { repo.remove(nil) }.to raise_error(ArgumentError)
      end
    end

    describe '#clear' do
      before do
        repo.add(vehicle)
        repo.add(slot)
        repo.add(entry_point)
      end

      it 'removes all objects from the repository' do
        repo.clear
        expect(repo.empty?).to be true
        expect(repo.all(SmallVehicle)).to be_empty
        expect(repo.all(SmallParkingSlot)).to be_empty
        expect(repo.all(EntryPoint)).to be_empty
      end

      it 'allows adding objects after clearing' do
        repo.clear
        expect(repo.add(vehicle)).to eq(vehicle)
        expect(repo.find(SmallVehicle, 'ABC123')).to eq(vehicle)
      end
    end
  end

  describe 'type-specific retrieval' do
    let(:repo) { InMemoryRepository.new }
    let(:vehicle1) { SmallVehicle.new('V1') }
    let(:vehicle2) { SmallVehicle.new('V2') }
    let(:slot1) { SmallParkingSlot.new(1, [1, 2, 3]) }
    let(:slot2) { SmallParkingSlot.new(2, [4, 5, 6]) }
    let(:entry_point) { EntryPoint.new(0) }

    before do
      repo.add(vehicle1)
      repo.add(vehicle2)
      repo.add(slot1)
      repo.add(slot2)
      repo.add(entry_point)
    end

    it 'finds vehicles by type' do
      vehicles = repo.all(SmallVehicle)
      expect(vehicles.size).to eq(2)
      expect(vehicles).to include(vehicle1)
      expect(vehicles).to include(vehicle2)
    end

    it 'finds parking slots by type' do
      slots = repo.all(SmallParkingSlot)
      expect(slots.size).to eq(2)
      expect(slots).to include(slot1)
      expect(slots).to include(slot2)
    end

    it 'finds entry points by type' do
      entry_points = repo.all(EntryPoint)
      expect(entry_points.size).to eq(1)
      expect(entry_points).to include(entry_point)
    end
  end

  describe 'thread safety' do
    it 'is thread-safe' do
      repo = InMemoryRepository.new

      # We'll add objects from multiple threads and ensure they're all added correctly
      vehicle_count = 100

      # Add vehicles from multiple threads
      threads = (0...vehicle_count).map do |i|
        Thread.new do
          vehicle = SmallVehicle.new("V#{i}")
          repo.add(vehicle)
        end
      end

      # Wait for all threads to complete
      threads.each(&:join)

      # Verify all vehicles were added
      vehicles = repo.all(SmallVehicle)
      expect(vehicles.size).to eq(vehicle_count)

      # Verify all expected vehicles are present
      (0...vehicle_count).each do |i|
        expect(repo.find(SmallVehicle, "V#{i}")).not_to be_nil
      end
    end
  end
end
