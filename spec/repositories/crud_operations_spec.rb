# frozen_string_literal: true

require 'spec_helper'
require 'repositories/in_memory_repository'
require 'models/small_vehicle'
require 'models/medium_vehicle'
require 'models/large_vehicle'
require 'models/small_parking_slot'
require 'models/medium_parking_slot'
require 'models/large_parking_slot'
require 'models/entry_point'
require 'models/parking_ticket'

def ticket_key(ticket)
  "#{ticket.vehicle.id}_#{ticket.entry_time.to_i}_#{ticket.slot.id}"
end

RSpec.describe 'Repository CRUD Operations' do
  let(:repo) { InMemoryRepository.new }

  # Create test objects
  let(:small_vehicle) { SmallVehicle.new('SV-001') }
  let(:medium_vehicle) { MediumVehicle.new('MV-001') }
  let(:large_vehicle) { LargeVehicle.new('LV-001') }

  let(:small_slot) { SmallParkingSlot.new(1, [1, 2, 3]) }
  let(:medium_slot) { MediumParkingSlot.new(2, [4, 5, 6]) }
  let(:large_slot) { LargeParkingSlot.new(3, [7, 8, 9]) }

  let(:entry_point1) { EntryPoint.new(0) }
  let(:entry_point2) { EntryPoint.new(1) }

  let(:entry_time) { Time.new(2023, 6, 10, 10, 0, 0) }
  let(:exit_time) { entry_time + (2 * 3600) } # 2 hours later
  let(:ticket) { ParkingTicket.new(small_vehicle, small_slot, entry_point1, entry_time) }

  describe 'Create (Add) Operations' do
    it 'adds multiple objects of the same type' do
      # Add multiple vehicles
      repo.add(small_vehicle)
      repo.add(medium_vehicle)
      repo.add(large_vehicle)

      # Verify all vehicles were added
      expect(repo.all(SmallVehicle)).to include(small_vehicle)
      expect(repo.all(MediumVehicle)).to include(medium_vehicle)
      expect(repo.all(LargeVehicle)).to include(large_vehicle)
    end

    it 'updates an object if the id already exists' do
      # Add a vehicle
      repo.add(small_vehicle)

      # Create another vehicle with the same id but different instance
      duplicate_vehicle = SmallVehicle.new('SV-001')
      repo.add(duplicate_vehicle)

      # Verify the repository contains only one vehicle with this id
      vehicles = repo.all(SmallVehicle)
      expect(vehicles.size).to eq(1)

      # The repository should now contain the most recently added vehicle
      stored_vehicle = repo.find(SmallVehicle, 'SV-001')
      expect(stored_vehicle).to eq(duplicate_vehicle)
    end

    it 'adds a parking ticket with references to other objects' do
      # Add the referenced objects first
      repo.add(small_vehicle)
      repo.add(small_slot)
      repo.add(entry_point1)

      # Add the ticket
      repo.add(ticket)

      # Retrieve the ticket using the composite key
      stored_ticket = repo.find(ParkingTicket, ticket_key(ticket))

      # Verify the ticket and its references
      expect(stored_ticket).to eq(ticket)
      expect(stored_ticket.vehicle).to eq(small_vehicle)
      expect(stored_ticket.slot).to eq(small_slot)
      expect(stored_ticket.entry_point).to eq(entry_point1)
    end
  end

  describe 'Read Operations' do
    before do
      # Populate the repository
      repo.add(small_vehicle)
      repo.add(medium_vehicle)
      repo.add(large_vehicle)
      repo.add(small_slot)
      repo.add(medium_slot)
      repo.add(large_slot)
      repo.add(entry_point1)
      repo.add(entry_point2)

      # Add a ticket with exit time
      ticket.exit_time = exit_time
      repo.add(ticket)
    end

    it 'finds objects by specific criteria' do
      # Get all vehicles
      vehicles = repo.all(SmallVehicle) + repo.all(MediumVehicle) + repo.all(LargeVehicle)
      expect(vehicles.size).to eq(3)

      # Get all parking slots
      slots = repo.all(SmallParkingSlot) + repo.all(MediumParkingSlot) + repo.all(LargeParkingSlot)
      expect(slots.size).to eq(3)

      # Get all entry points
      entry_points = repo.all(EntryPoint)
      expect(entry_points.size).to eq(2)
    end

    it 'finds a specific object by type and id' do
      # Find specific vehicle
      found_vehicle = repo.find(SmallVehicle, 'SV-001')
      expect(found_vehicle).to eq(small_vehicle)

      # Find specific slot
      found_slot = repo.find(MediumParkingSlot, 2)
      expect(found_slot).to eq(medium_slot)

      # Find specific entry point
      found_entry_point = repo.find(EntryPoint, 1)
      expect(found_entry_point).to eq(entry_point2)
    end

    it 'returns nil when object is not found' do
      # Try to find non-existent vehicle
      non_existent = repo.find(SmallVehicle, 'NONEXISTENT')
      expect(non_existent).to be_nil
    end

    it 'finds tickets by composite key' do
      # Find the ticket using the composite key
      found_ticket = repo.find(ParkingTicket, ticket_key(ticket))
      expect(found_ticket).to eq(ticket)
      expect(found_ticket.entry_time).to eq(entry_time)
      expect(found_ticket.exit_time).to eq(exit_time)
    end
  end

  describe 'Update Operations' do
    before do
      # Populate the repository
      repo.add(small_vehicle)
      repo.add(small_slot)
      repo.add(entry_point1)
      repo.add(ticket)
    end

    it 'updates an object by adding it again with the same id' do
      # Update the exit time of the ticket
      updated_ticket = ticket.dup
      updated_ticket.exit_time = exit_time

      # Add the updated ticket (this should replace the original since the key attributes are the same)
      repo.add(updated_ticket)

      # Retrieve the updated ticket using the composite key
      stored_ticket = repo.find(ParkingTicket, ticket_key(ticket))

      # Verify the update
      expect(stored_ticket.exit_time).to eq(exit_time)
    end

    it 'preserves object references after update' do
      # Create a new slot and update the ticket to use it
      new_slot = MediumParkingSlot.new(4, [10, 11, 12])
      repo.add(new_slot)

      # Create an updated ticket with the new slot
      updated_ticket = ParkingTicket.new(small_vehicle, new_slot, entry_point1, entry_time)
      updated_ticket.exit_time = exit_time

      # Add the updated ticket
      repo.add(updated_ticket)

      # Retrieve the updated ticket using its composite key
      stored_ticket = repo.find(ParkingTicket, ticket_key(updated_ticket))

      # Verify the references are preserved
      expect(stored_ticket.vehicle).to eq(small_vehicle)
      expect(stored_ticket.slot).to eq(new_slot)
      expect(stored_ticket.entry_point).to eq(entry_point1)
    end
  end

  describe 'Delete Operations' do
    before do
      # Populate the repository
      repo.add(small_vehicle)
      repo.add(medium_vehicle)
      repo.add(small_slot)
      repo.add(medium_slot)
      repo.add(entry_point1)
      repo.add(ticket)
    end

    it 'removes a specific object' do
      # Remove a vehicle
      repo.remove(small_vehicle)

      # Verify it was removed
      expect(repo.find(SmallVehicle, 'SV-001')).to be_nil

      # Verify other objects are still there
      expect(repo.find(MediumVehicle, 'MV-001')).to eq(medium_vehicle)
    end

    it 'removes a ticket' do
      # Remove the ticket
      repo.remove(ticket)

      # Verify it was removed
      expect(repo.find(ParkingTicket, ticket.object_id)).to be_nil

      # Verify referenced objects are still there
      expect(repo.find(SmallVehicle, 'SV-001')).to eq(small_vehicle)
      expect(repo.find(SmallParkingSlot, 1)).to eq(small_slot)
      expect(repo.find(EntryPoint, 0)).to eq(entry_point1)
    end

    it 'handles removing non-existent objects' do
      # Try to remove a non-existent vehicle
      non_existent_vehicle = SmallVehicle.new('NONEXISTENT')
      result = repo.remove(non_existent_vehicle)

      # Verify it returns nil
      expect(result).to be_nil

      # Verify repository state is unchanged
      expect(repo.all(SmallVehicle)).to include(small_vehicle)
    end

    it 'clears all objects' do
      # Clear the repository
      repo.clear

      # Verify all objects were removed
      expect(repo.empty?).to be true
      expect(repo.all(SmallVehicle)).to be_empty
      expect(repo.all(MediumVehicle)).to be_empty
      expect(repo.all(SmallParkingSlot)).to be_empty
      expect(repo.all(MediumParkingSlot)).to be_empty
      expect(repo.all(EntryPoint)).to be_empty
      expect(repo.all(ParkingTicket)).to be_empty
    end
  end

  describe 'Complex Operations' do
    it 'handles a complete parking scenario' do
      # Create and store all necessary objects
      repo.add(small_vehicle)
      repo.add(small_slot)
      repo.add(entry_point1)

      # Create and store a parking ticket (vehicle enters)
      parking_ticket = ParkingTicket.new(small_vehicle, small_slot, entry_point1, entry_time)
      repo.add(parking_ticket)

      # Update the ticket when the vehicle exits
      exiting_ticket = repo.find(ParkingTicket, ticket_key(parking_ticket))
      exiting_ticket.exit_time = exit_time
      repo.add(exiting_ticket)

      # Retrieve the final ticket
      final_ticket = repo.find(ParkingTicket, ticket_key(parking_ticket))

      # Verify the scenario
      expect(final_ticket.vehicle).to eq(small_vehicle)
      expect(final_ticket.slot).to eq(small_slot)
      expect(final_ticket.entry_point).to eq(entry_point1)
      expect(final_ticket.entry_time).to eq(entry_time)
      expect(final_ticket.exit_time).to eq(exit_time)
    end

    it 'correctly handles bulk operations' do
      # Add multiple objects of different types
      vehicles = [small_vehicle, medium_vehicle, large_vehicle]
      slots = [small_slot, medium_slot, large_slot]
      entry_points = [entry_point1, entry_point2]

      # Add all objects
      vehicles.each { |vehicle| repo.add(vehicle) }
      slots.each { |slot| repo.add(slot) }
      entry_points.each { |ep| repo.add(ep) }

      # Verify all objects were added
      expect(repo.all(SmallVehicle).size + repo.all(MediumVehicle).size + repo.all(LargeVehicle).size).to eq(vehicles.size)
      expect(repo.all(SmallParkingSlot).size + repo.all(MediumParkingSlot).size + repo.all(LargeParkingSlot).size).to eq(slots.size)
      expect(repo.all(EntryPoint).size).to eq(entry_points.size)

      # Remove half of each type
      repo.remove(vehicles[0])
      repo.remove(slots[0])
      repo.remove(entry_points[0])

      # Verify the remaining objects
      expect(repo.all(SmallVehicle).size + repo.all(MediumVehicle).size + repo.all(LargeVehicle).size).to eq(vehicles.size - 1)
      expect(repo.all(SmallParkingSlot).size + repo.all(MediumParkingSlot).size + repo.all(LargeParkingSlot).size).to eq(slots.size - 1)
      expect(repo.all(EntryPoint).size).to eq(entry_points.size - 1)
    end
  end
end
