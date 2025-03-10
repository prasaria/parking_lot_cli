# frozen_string_literal: true

require 'spec_helper'
require 'services/vehicle_tracker'
require 'models/small_vehicle'
require 'models/medium_vehicle'
require 'models/large_vehicle'
require 'models/small_parking_slot'
require 'models/entry_point'
require 'models/parking_ticket'
require 'time'

RSpec.describe 'Vehicle Exit Tracking' do
  let(:tracker) { VehicleTracker.new }
  let(:vehicle) { SmallVehicle.new('ABC123') }
  let(:slot) { SmallParkingSlot.new(1, [3, 5, 7]) }
  let(:entry_point) { EntryPoint.new(0) }
  let(:entry_time) { Time.new(2023, 6, 10, 10, 0, 0) }
  let(:exit_time) { entry_time + (2 * 3600) } # 2 hours later

  describe 'detailed exit tracking' do
    before do
      # Setup: Park a vehicle
      @ticket = ParkingTicket.new(vehicle, slot, entry_point, entry_time)
      tracker.track_vehicle_entry(@ticket)
    end

    context 'when a vehicle exits' do
      it 'properly records the exit time' do
        @ticket.exit_time = exit_time
        tracker.track_vehicle_exit(@ticket)

        # Verify the exit was recorded by checking recently_exited?
        check_time = exit_time + (30 * 60) # 30 minutes after exit
        expect(tracker.recently_exited?(vehicle, check_time)).to be true
      end

      it 'preserves the ticket in the vehicle history' do
        @ticket.exit_time = exit_time
        tracker.track_vehicle_exit(@ticket)

        history = tracker.get_tickets_history(vehicle)
        expect(history).to include(@ticket)
        expect(history.size).to eq(1)
      end

      it 'records the correct exit time for continuous rate calculations' do
        @ticket.exit_time = exit_time
        tracker.track_vehicle_exit(@ticket)

        # Check that the exit time is correctly used in recently_exited?
        just_within_window = exit_time + (59 * 60) # 59 minutes after exit
        just_outside_window = exit_time + (61 * 60) # 61 minutes after exit

        expect(tracker.recently_exited?(vehicle, just_within_window)).to be true
        expect(tracker.recently_exited?(vehicle, just_outside_window)).to be false
      end
    end

    context 'with multiple vehicles exiting at different times' do
      let(:vehicle2) { SmallVehicle.new('XYZ789') }
      let(:entry_time2) { Time.new(2023, 6, 10, 11, 0, 0) }
      let(:exit_time2) { entry_time2 + (3 * 3600) } # 3 hours later

      before do
        # Setup: Park a second vehicle
        @ticket2 = ParkingTicket.new(vehicle2, slot, entry_point, entry_time2)
        tracker.track_vehicle_entry(@ticket2)
      end

      it 'maintains separate exit records for each vehicle' do
        # First vehicle exits
        @ticket.exit_time = exit_time
        tracker.track_vehicle_exit(@ticket)

        # Second vehicle exits later
        @ticket2.exit_time = exit_time2
        tracker.track_vehicle_exit(@ticket2)

        # Check exit times are tracked correctly for both
        check_time1 = exit_time + (30 * 60) # 30 minutes after first exit
        check_time2 = exit_time2 + (30 * 60) # 30 minutes after second exit

        expect(tracker.recently_exited?(vehicle, check_time1)).to be true
        expect(tracker.recently_exited?(vehicle2, check_time2)).to be true

        # Vehicle 1 should not be considered recently exited at check_time2
        # if check_time2 is more than 1 hour after vehicle 1's exit
        expect(tracker.recently_exited?(vehicle, check_time2)).to be false if (check_time2 - exit_time) / 3600.0 > 1.0
      end
    end

    context 'with a vehicle that exits and returns multiple times' do
      it 'updates the exit time record on each exit' do
        # First exit
        @ticket.exit_time = exit_time
        tracker.track_vehicle_exit(@ticket)

        # Vehicle returns and exits again
        new_entry_time = exit_time + (30 * 60) # 30 minutes after first exit
        new_exit_time = new_entry_time + (1 * 3600) # 1 hour after second entry
        new_ticket = ParkingTicket.new(vehicle, slot, entry_point, new_entry_time)
        tracker.track_vehicle_entry(new_ticket)
        new_ticket.exit_time = new_exit_time
        tracker.track_vehicle_exit(new_ticket)

        # Check that the most recent exit time is used
        check_time = new_exit_time + (30 * 60) # 30 minutes after second exit
        expect(tracker.recently_exited?(vehicle, check_time)).to be true

        # The previous ticket should be retrievable
        previous_ticket = tracker.get_previous_ticket(vehicle)
        expect(previous_ticket).to eq(new_ticket)
      end

      it 'maintains the correct history order of entries and exits' do
        # First exit
        @ticket.exit_time = exit_time
        tracker.track_vehicle_exit(@ticket)

        # Vehicle returns and exits again
        new_entry_time = exit_time + (30 * 60) # 30 minutes after first exit
        new_exit_time = new_entry_time + (1 * 3600) # 1 hour after second entry
        new_ticket = ParkingTicket.new(vehicle, slot, entry_point, new_entry_time)
        tracker.track_vehicle_entry(new_ticket)
        new_ticket.exit_time = new_exit_time
        tracker.track_vehicle_exit(new_ticket)

        # Check history order
        history = tracker.get_tickets_history(vehicle)
        expect(history.size).to eq(2)
        expect(history[0]).to eq(@ticket)
        expect(history[1]).to eq(new_ticket)
      end
    end

    context 'with edge cases' do
      it 'handles very short stays correctly' do
        # Vehicle exits almost immediately
        quick_exit_time = entry_time + (5 * 60) # Just 5 minutes later
        @ticket.exit_time = quick_exit_time
        tracker.track_vehicle_exit(@ticket)

        # Check exit was recorded
        check_time = quick_exit_time + (30 * 60) # 30 minutes after exit
        expect(tracker.recently_exited?(vehicle, check_time)).to be true
      end

      it 'handles exit times at exactly the window boundary' do
        @ticket.exit_time = exit_time
        tracker.track_vehicle_exit(@ticket)

        # Check at exactly 1 hour after exit
        check_time = exit_time + (60 * 60) # Exactly 1 hour after exit
        expect(tracker.recently_exited?(vehicle, check_time)).to be true

        # Check just after 1 hour after exit
        check_time = exit_time + (60 * 60) + 1 # 1 hour and 1 second after exit
        expect(tracker.recently_exited?(vehicle, check_time)).to be false
      end

      it 'handles custom time windows for recently_exited?' do
        @ticket.exit_time = exit_time
        tracker.track_vehicle_exit(@ticket)

        # Check with a 2-hour window
        check_time = exit_time + (90 * 60) # 1.5 hours after exit
        expect(tracker.recently_exited?(vehicle, check_time, 2)).to be true
        expect(tracker.recently_exited?(vehicle, check_time)).to be false # Default 1-hour window
      end
    end
  end
end
