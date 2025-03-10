# frozen_string_literal: true

require 'spec_helper'
require 'services/vehicle_tracker'
require 'models/small_vehicle'
require 'models/medium_vehicle'
require 'models/large_vehicle'
require 'models/small_parking_slot'
require 'models/entry_point'
require 'models/parking_ticket'

RSpec.describe VehicleTracker do
  let(:tracker) { VehicleTracker.new }
  let(:vehicle) { SmallVehicle.new('ABC123') }
  let(:slot) { SmallParkingSlot.new(1, [3, 5, 7]) }
  let(:entry_point) { EntryPoint.new(0) }

  describe '#track_vehicle_entry' do
    it 'tracks a vehicle entering the parking complex' do
      entry_time = Time.new(2023, 6, 10, 10, 0, 0)
      ticket = ParkingTicket.new(vehicle, slot, entry_point, entry_time)

      tracker.track_vehicle_entry(ticket)

      expect(tracker.currently_parked?(vehicle)).to be true
    end

    it 'raises an error if the vehicle is already parked' do
      entry_time = Time.new(2023, 6, 10, 10, 0, 0)
      ticket = ParkingTicket.new(vehicle, slot, entry_point, entry_time)

      tracker.track_vehicle_entry(ticket)

      expect { tracker.track_vehicle_entry(ticket) }.to raise_error(ArgumentError)
    end

    it 'raises an error if the ticket is nil' do
      expect { tracker.track_vehicle_entry(nil) }.to raise_error(ArgumentError)
    end
  end

  describe '#track_vehicle_exit' do
    it 'tracks a vehicle exiting the parking complex' do
      entry_time = Time.new(2023, 6, 10, 10, 0, 0)
      exit_time = entry_time + (2 * 3600) # 2 hours later
      ticket = ParkingTicket.new(vehicle, slot, entry_point, entry_time)

      tracker.track_vehicle_entry(ticket)
      ticket.exit_time = exit_time
      tracker.track_vehicle_exit(ticket)

      expect(tracker.currently_parked?(vehicle)).to be false
    end

    it 'raises an error if the vehicle is not currently parked' do
      entry_time = Time.new(2023, 6, 10, 10, 0, 0)
      exit_time = entry_time + (2 * 3600) # 2 hours later
      ticket = ParkingTicket.new(vehicle, slot, entry_point, entry_time)
      ticket.exit_time = exit_time

      expect { tracker.track_vehicle_exit(ticket) }.to raise_error(ArgumentError)
    end

    it 'raises an error if the ticket is nil' do
      expect { tracker.track_vehicle_exit(nil) }.to raise_error(ArgumentError)
    end

    it 'raises an error if the ticket has no exit time' do
      entry_time = Time.new(2023, 6, 10, 10, 0, 0)
      ticket = ParkingTicket.new(vehicle, slot, entry_point, entry_time)

      tracker.track_vehicle_entry(ticket)

      expect { tracker.track_vehicle_exit(ticket) }.to raise_error(ArgumentError)
    end
  end

  describe '#currently_parked?' do
    it 'returns true if the vehicle is currently parked' do
      entry_time = Time.new(2023, 6, 10, 10, 0, 0)
      ticket = ParkingTicket.new(vehicle, slot, entry_point, entry_time)

      tracker.track_vehicle_entry(ticket)

      expect(tracker.currently_parked?(vehicle)).to be true
    end

    it 'returns false if the vehicle is not currently parked' do
      expect(tracker.currently_parked?(vehicle)).to be false
    end

    it 'returns false if the vehicle has exited' do
      entry_time = Time.new(2023, 6, 10, 10, 0, 0)
      exit_time = entry_time + (2 * 3600) # 2 hours later
      ticket = ParkingTicket.new(vehicle, slot, entry_point, entry_time)

      tracker.track_vehicle_entry(ticket)
      ticket.exit_time = exit_time
      tracker.track_vehicle_exit(ticket)

      expect(tracker.currently_parked?(vehicle)).to be false
    end
  end

  describe '#get_active_ticket' do
    it 'returns the active ticket for a parked vehicle' do
      entry_time = Time.new(2023, 6, 10, 10, 0, 0)
      ticket = ParkingTicket.new(vehicle, slot, entry_point, entry_time)

      tracker.track_vehicle_entry(ticket)

      expect(tracker.get_active_ticket(vehicle)).to eq(ticket)
    end

    it 'returns nil if the vehicle is not currently parked' do
      expect(tracker.get_active_ticket(vehicle)).to be_nil
    end
  end

  describe '#recently_exited?' do
    it 'returns true if the vehicle exited within the specified time window' do
      entry_time = Time.new(2023, 6, 10, 10, 0, 0)
      exit_time = entry_time + (2 * 3600) # 2 hours later
      ticket = ParkingTicket.new(vehicle, slot, entry_point, entry_time)

      tracker.track_vehicle_entry(ticket)
      ticket.exit_time = exit_time
      tracker.track_vehicle_exit(ticket)

      # Check if recently exited (within 1 hour of exit)
      check_time = exit_time + (30 * 60) # 30 minutes after exit
      expect(tracker.recently_exited?(vehicle, check_time, 1)).to be true
    end

    it 'returns false if the vehicle exited outside the specified time window' do
      entry_time = Time.new(2023, 6, 10, 10, 0, 0)
      exit_time = entry_time + (2 * 3600) # 2 hours later
      ticket = ParkingTicket.new(vehicle, slot, entry_point, entry_time)

      tracker.track_vehicle_entry(ticket)
      ticket.exit_time = exit_time
      tracker.track_vehicle_exit(ticket)

      # Check if recently exited (after 2 hours of exit)
      check_time = exit_time + (2 * 3600) # 2 hours after exit
      expect(tracker.recently_exited?(vehicle, check_time, 1)).to be false
    end

    it 'returns false if the vehicle has never been parked' do
      check_time = Time.new(2023, 6, 10, 10, 0, 0)
      expect(tracker.recently_exited?(vehicle, check_time, 1)).to be false
    end
  end

  describe '#get_previous_ticket' do
    it 'returns the most recent ticket for a vehicle that has exited' do
      entry_time = Time.new(2023, 6, 10, 10, 0, 0)
      exit_time = entry_time + (2 * 3600) # 2 hours later
      ticket = ParkingTicket.new(vehicle, slot, entry_point, entry_time)

      tracker.track_vehicle_entry(ticket)
      ticket.exit_time = exit_time
      tracker.track_vehicle_exit(ticket)

      expect(tracker.get_previous_ticket(vehicle)).to eq(ticket)
    end

    it 'returns nil if the vehicle has never been parked' do
      expect(tracker.get_previous_ticket(vehicle)).to be_nil
    end

    it 'returns nil if the vehicle is currently parked (no previous ticket)' do
      entry_time = Time.new(2023, 6, 10, 10, 0, 0)
      ticket = ParkingTicket.new(vehicle, slot, entry_point, entry_time)

      tracker.track_vehicle_entry(ticket)

      expect(tracker.get_previous_ticket(vehicle)).to be_nil
    end
  end

  describe '#get_tickets_history' do
    let(:other_vehicle) { SmallVehicle.new('XYZ789') }

    it 'returns an empty array for a vehicle with no history' do
      expect(tracker.get_tickets_history(vehicle)).to eq([])
    end

    it 'returns all tickets for a vehicle with multiple entries and exits' do
      # First parking
      first_entry_time = Time.new(2023, 6, 10, 10, 0, 0)
      first_exit_time = first_entry_time + (2 * 3600) # 2 hours later
      first_ticket = ParkingTicket.new(vehicle, slot, entry_point, first_entry_time)

      tracker.track_vehicle_entry(first_ticket)
      first_ticket.exit_time = first_exit_time
      tracker.track_vehicle_exit(first_ticket)

      # Second parking
      second_entry_time = first_exit_time + 3600 # 1 hour after first exit
      second_exit_time = second_entry_time + (3 * 3600) # 3 hours later
      second_ticket = ParkingTicket.new(vehicle, slot, entry_point, second_entry_time)

      tracker.track_vehicle_entry(second_ticket)
      second_ticket.exit_time = second_exit_time
      tracker.track_vehicle_exit(second_ticket)

      # Third parking (still active)
      third_entry_time = second_exit_time + (2 * 3600) # 2 hours after second exit
      third_ticket = ParkingTicket.new(vehicle, slot, entry_point, third_entry_time)

      tracker.track_vehicle_entry(third_ticket)

      # Check history - should include all tickets
      history = tracker.get_tickets_history(vehicle)
      expect(history.size).to eq(3)
      expect(history).to include(first_ticket, second_ticket, third_ticket)
      expect(history).to eq([first_ticket, second_ticket, third_ticket]) # Order should be preserved
    end

    it 'returns tickets only for the specified vehicle' do
      # Track multiple vehicles
      vehicle_ticket = ParkingTicket.new(vehicle, slot, entry_point, Time.now)
      other_ticket = ParkingTicket.new(other_vehicle, slot, entry_point, Time.now)

      tracker.track_vehicle_entry(vehicle_ticket)
      tracker.track_vehicle_entry(other_ticket)

      # Check history for first vehicle
      history = tracker.get_tickets_history(vehicle)
      expect(history.size).to eq(1)
      expect(history).to include(vehicle_ticket)
      expect(history).not_to include(other_ticket)
    end
  end
end
