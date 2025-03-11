# frozen_string_literal: true

require 'spec_helper'
require 'cli/command_handler'
require 'models/parking_complex'
require 'models/entry_point'
require 'models/small_parking_slot'
require 'models/medium_parking_slot'
require 'models/large_parking_slot'
require 'models/small_vehicle'
require 'models/medium_vehicle'
require 'models/large_vehicle'

RSpec.describe CommandHandler do
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

  describe '#parse_command' do
    it 'parses valid commands' do
      command = 'park SV123 small 0'
      parsed = handler.parse_command(command)

      expect(parsed[:command]).to eq('park')
      expect(parsed[:args]).to eq(%w[SV123 small 0])
    end

    it 'handles commands with extra whitespace' do
      command = '  park   SV123   small  0  '
      parsed = handler.parse_command(command)

      expect(parsed[:command]).to eq('park')
      expect(parsed[:args]).to eq(%w[SV123 small 0])
    end

    it 'returns nil for empty commands' do
      expect(handler.parse_command('')).to be_nil
      expect(handler.parse_command('  ')).to be_nil
    end

    it 'returns nil for nil commands' do
      expect(handler.parse_command(nil)).to be_nil
    end
  end

  describe '#execute_command' do
    context 'help command' do
      it 'returns help information' do
        result = handler.execute_command('help')

        expect(result[:success]).to be true
        expect(result[:message]).to include('Available commands')
        expect(result[:message]).to include('park')
        expect(result[:message]).to include('unpark')
      end
    end

    context 'status command' do
      it 'returns parking complex status' do
        result = handler.execute_command('status')

        expect(result[:success]).to be true
        expect(result[:message]).to include('Parking Complex Status')
        expect(result[:message]).to include('Entry Points: 3')
        expect(result[:message]).to include('Parking Slots: 3')
        expect(result[:message]).to include('Parked Vehicles: 0')
      end
    end

    context 'park command' do
      it 'successfully parks a vehicle' do
        result = handler.execute_command('park SV123 small 0')

        expect(result[:success]).to be true
        expect(result[:message]).to include('Vehicle SV123 parked successfully')
        expect(result[:message]).to include('Slot ID: 1')
        expect(result[:message]).to include('Entry Point: 0')
      end

      it 'handles invalid vehicle type' do
        result = handler.execute_command('park SV123 invalid_type 0')

        expect(result[:success]).to be false
        expect(result[:message]).to include('Invalid vehicle type')
      end

      it 'handles invalid entry point' do
        result = handler.execute_command('park SV123 small 99')

        expect(result[:success]).to be false
        expect(result[:message]).to include('Entry point not found')
      end

      it 'handles missing arguments' do
        result = handler.execute_command('park SV123')

        expect(result[:success]).to be false
        expect(result[:message]).to include('Invalid command format')
      end

      it 'handles no available slots' do
        # Park vehicles in all slots first
        handler.execute_command('park SV1 small 0')
        handler.execute_command('park MV1 medium 0')
        handler.execute_command('park LV1 large 0')

        # Try to park another vehicle
        result = handler.execute_command('park SV2 small 0')

        expect(result[:success]).to be false
        expect(result[:message]).to include('No available slot')
      end

      it 'handles already parked vehicle' do
        # Park a vehicle
        handler.execute_command('park SV123 small 0')

        # Try to park the same vehicle again
        result = handler.execute_command('park SV123 small 0')

        expect(result[:success]).to be false
        expect(result[:message]).to include('already parked')
      end
    end

    context 'unpark command' do
      before do
        # Park a vehicle first
        handler.execute_command('park SV123 small 0')
      end

      it 'successfully unparks a vehicle' do
        result = handler.execute_command('unpark SV123')

        expect(result[:success]).to be true
        expect(result[:message]).to include('Vehicle SV123 unparked successfully')
        expect(result[:message]).to include('Fee: ')
      end

      it 'handles vehicle not found' do
        result = handler.execute_command('unpark NOTFOUND')

        expect(result[:success]).to be false
        expect(result[:message]).to include('not parked')
      end

      it 'handles missing arguments' do
        result = handler.execute_command('unpark')

        expect(result[:success]).to be false
        expect(result[:message]).to include('Invalid command format')
      end
    end

    context 'slots command' do
      it 'lists all parking slots' do
        result = handler.execute_command('slots')

        expect(result[:success]).to be true
        expect(result[:message]).to include('Parking Slots')
        expect(result[:message]).to include('ID: 1')
        expect(result[:message]).to include('ID: 2')
        expect(result[:message]).to include('ID: 3')
      end

      it 'filters slots by type' do
        result = handler.execute_command('slots small')

        expect(result[:success]).to be true
        expect(result[:message]).to include('Small Parking Slots')
        expect(result[:message]).to include('ID: 1')
        expect(result[:message]).not_to include('ID: 2') # Medium
        expect(result[:message]).not_to include('ID: 3') # Large
      end

      it 'handles invalid slot type' do
        result = handler.execute_command('slots invalid_type')

        expect(result[:success]).to be false
        expect(result[:message]).to include('Invalid slot type')
      end
    end

    context 'vehicles command' do
      before do
        # Park some vehicles
        handler.execute_command('park SV123 small 0')
        handler.execute_command('park MV456 medium 1')
      end

      it 'lists all parked vehicles' do
        result = handler.execute_command('vehicles')

        expect(result[:success]).to be true
        expect(result[:message]).to include('Parked Vehicles')
        expect(result[:message]).to include('SV123')
        expect(result[:message]).to include('MV456')
      end
    end

    context 'exit command' do
      it 'returns exit message' do
        result = handler.execute_command('exit')

        expect(result[:success]).to be true
        expect(result[:message]).to include('Exiting')
      end
    end

    context 'invalid command' do
      it 'handles unknown commands' do
        result = handler.execute_command('unknown_command')

        expect(result[:success]).to be false
        expect(result[:message]).to include('Unknown command')
      end
    end
  end
end
