# frozen_string_literal: true

require 'spec_helper'
require 'cli/command_handler'
require 'models/parking_complex'
require 'models/entry_point'
require 'models/small_parking_slot'
require 'models/medium_parking_slot'
require 'models/large_parking_slot'

RSpec.describe 'Command Execution' do
  # Set up a parking complex with entry points and slots
  let(:entry_points) { [EntryPoint.new(0), EntryPoint.new(1), EntryPoint.new(2)] }
  let(:parking_slots) do
    [
      SmallParkingSlot.new(1, [1, 4, 7]),
      MediumParkingSlot.new(2, [2, 3, 8]),
      LargeParkingSlot.new(3, [5, 1, 6])
    ]
  end
  let(:parking_complex) { ParkingComplex.new(entry_points, parking_slots) }
  let(:handler) { CommandHandler.new(parking_complex) }

  # Mock input/output for testing
  let(:input) { StringIO.new }
  let(:output) { StringIO.new }

  # Helper method to execute a command and capture its output
  def execute_with_output(command)
    result = handler.execute_command(command)
    output.puts(result[:message])
    result
  end

  describe 'Command scenarios' do
    context 'Status and help commands' do
      it 'shows help information' do
        result = execute_with_output('help')

        expect(result[:success]).to be true
        expect(output.string).to include('Available commands')
      end

      it 'shows parking complex status' do
        result = execute_with_output('status')

        expect(result[:success]).to be true
        expect(output.string).to include('Parking Complex Status')
        expect(output.string).to include('Entry Points: 3')
        expect(output.string).to include('Parking Slots: 3')
      end
    end

    context 'Parking operations' do
      it 'executes a complete parking and unparking sequence' do
        # Park a vehicle
        park_result = execute_with_output('park SV123 small 0')
        expect(park_result[:success]).to be true
        expect(output.string).to include('Vehicle SV123 parked successfully')

        # Check status after parking
        status_result = execute_with_output('status')
        expect(status_result[:success]).to be true
        expect(output.string).to include('Parked Vehicles: 1')

        # List vehicles
        vehicles_result = execute_with_output('vehicles')
        expect(vehicles_result[:success]).to be true
        expect(output.string).to include('SV123')

        # Unpark the vehicle
        unpark_result = execute_with_output('unpark SV123')
        expect(unpark_result[:success]).to be true
        expect(output.string).to include('Vehicle SV123 unparked successfully')
        expect(output.string).to include('Fee:')

        # Check status after unparking
        final_status_result = execute_with_output('status')
        expect(final_status_result[:success]).to be true
        expect(output.string).to include('Parked Vehicles: 0')
      end

      it 'handles parking when no slots are available' do
        # Park vehicles in all available slots
        execute_with_output('park SV1 small 0')
        execute_with_output('park MV1 medium 0')
        execute_with_output('park LV1 large 0')

        # Try to park another vehicle
        result = execute_with_output('park SV2 small 0')
        expect(result[:success]).to be false
        expect(output.string).to include('No available slot')
      end

      it 'demonstrates slot allocation strategy' do
        # Park a small vehicle at entry point 0
        # Closest slot from entry point 0 is the small slot (ID: 1) with distance 1
        result1 = execute_with_output('park SV1 small 0')
        expect(result1[:success]).to be true
        expect(output.string).to include('Slot ID: 1')

        # Park another small vehicle at entry point 0
        # Now the closest available slot is the medium slot (ID: 2) with distance 2
        result2 = execute_with_output('park SV2 small 0')
        expect(result2[:success]).to be true
        expect(output.string).to include('Slot ID: 2')

        # Park a medium vehicle at entry point 1
        # From entry point 1, the closest available slot is the large slot (ID: 3) with distance 1
        result3 = execute_with_output('park MV1 medium 1')
        expect(result3[:success]).to be true
        expect(output.string).to include('Slot ID: 3')
      end
    end

    context 'Slot management' do
      it 'lists all parking slots' do
        result = execute_with_output('slots')

        expect(result[:success]).to be true
        expect(output.string).to include('Parking Slots (3)')
        expect(output.string).to include('ID: 1')
        expect(output.string).to include('ID: 2')
        expect(output.string).to include('ID: 3')
      end

      it 'lists slots by type' do
        result = execute_with_output('slots small')

        expect(result[:success]).to be true
        expect(output.string).to include('Small Parking Slots')
        expect(output.string).to include('ID: 1')
        expect(output.string).not_to include('ID: 2') # Medium
        expect(output.string).not_to include('ID: 3') # Large
      end

      it 'updates slot status when parking/unparking' do
        # Check initial status - all slots available
        slots_result = execute_with_output('slots')
        expect(slots_result[:success]).to be true
        expect(output.string.scan('Status: Available').size).to eq(3)

        # Park a vehicle
        execute_with_output('park SV123 small 0')

        # Check status - one slot should be occupied
        slots_after_park = execute_with_output('slots')
        expect(slots_after_park[:success]).to be true
        expect(output.string.scan('Status: Available').size).to eq(5) # 3 initial + 2 remaining
        expect(output.string.scan('Status: Occupied').size).to eq(1)

        # Unpark the vehicle
        execute_with_output('unpark SV123')

        # Check status - all slots should be available again
        slots_after_unpark = execute_with_output('slots')
        expect(slots_after_unpark[:success]).to be true
        expect(output.string.scan('Status: Available').size).to eq(8) # 3 initial + 2 after park + 3 after unpark
        expect(output.string.scan('Status: Occupied').size).to eq(1) # Only the one from after_park output
      end
    end

    context 'Error handling' do
      it 'handles invalid commands gracefully' do
        result = execute_with_output('invalid_command')

        expect(result[:success]).to be false
        expect(output.string).to include('Unknown command')
      end

      it 'provides helpful error messages for missing arguments' do
        result = execute_with_output('park')

        expect(result[:success]).to be false
        expect(output.string).to include('Invalid command format')
        expect(output.string).to include('Usage:')
      end

      it 'indicates when a vehicle is not found' do
        result = execute_with_output('unpark NOTFOUND')

        expect(result[:success]).to be false
        expect(output.string).to include('not parked')
      end
    end

    context 'Complex scenarios' do
      it 'handles continuous rate parking' do
        # Mock Time.now to control exact times
        fixed_time = Time.new(2023, 6, 10, 10, 0, 0)
        allow(Time).to receive(:now).and_return(fixed_time)

        # Park a vehicle
        execute_with_output('park SV123 small 0')

        # Advance time 2 hours and unpark
        exit_time = fixed_time + (2 * 3600)
        allow(Time).to receive(:now).and_return(exit_time)
        unpark_result = execute_with_output('unpark SV123')
        expect(unpark_result[:success]).to be true

        # Advance time 30 minutes (within continuous rate window)
        return_time = exit_time + (30 * 60)
        allow(Time).to receive(:now).and_return(return_time)

        # Park the same vehicle again
        park_again_result = execute_with_output('park SV123 small 0')
        expect(park_again_result[:success]).to be true

        # Advance time 3 more hours
        final_exit_time = return_time + (3 * 3600)
        allow(Time).to receive(:now).and_return(final_exit_time)

        # Unpark again and check the fee
        final_unpark_result = execute_with_output('unpark SV123')
        expect(final_unpark_result[:success]).to be true

        # The fee should reflect the continuous rate
        # Total time: 2 hours + 0.5 hour gap + 3 hours = 5.5 hours (rounds up to 6)
        # Expected fee: Base rate (40) + 3 hours at small slot rate (3 * 20) = 100 pesos
        expect(output.string).to include('Fee: 100 pesos')
      end

      it 'demonstrates various vehicle-slot compatibility rules' do
        # Small vehicles can park in any slot type
        small_in_small = execute_with_output('park SV1 small 0')
        expect(small_in_small[:success]).to be true

        # Medium vehicles can only park in medium or large slots
        medium_in_small = execute_with_output('park MV1 medium 0')
        expect(medium_in_small[:success]).to be true
        expect(output.string).to include('Slot ID: 2') # Medium slot

        # Large vehicles can only park in large slots
        large_in_large = execute_with_output('park LV1 large 0')
        expect(large_in_large[:success]).to be true
        expect(output.string).to include('Slot ID: 3') # Large slot

        # Unpark all vehicles to clear slots
        execute_with_output('unpark SV1')
        execute_with_output('unpark MV1')
        execute_with_output('unpark LV1')

        # Now let's try parking in different order
        # Large vehicle first - should get large slot
        execute_with_output('park LV2 large 0')

        # Medium vehicle next - should get medium slot
        execute_with_output('park MV2 medium 0')

        # Small vehicle last - should get small slot
        execute_with_output('park SV2 small 0')

        # Check all vehicles are parked
        vehicles_result = execute_with_output('vehicles')
        expect(vehicles_result[:success]).to be true
        expect(output.string).to include('LV2')
        expect(output.string).to include('MV2')
        expect(output.string).to include('SV2')
      end
    end
  end
end
