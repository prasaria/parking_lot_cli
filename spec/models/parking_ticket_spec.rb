# frozen_string_literal: true

require 'spec_helper'
require 'models/parking_ticket'
require 'models/small_vehicle'
require 'models/small_parking_slot'
require 'models/entry_point'

RSpec.describe ParkingTicket do
  let(:vehicle) { SmallVehicle.new('ABC123') }
  let(:slot) { SmallParkingSlot.new(1, [3, 5, 7]) }
  let(:entry_point) { EntryPoint.new(0) }
  let(:entry_time) { Time.new(2023, 6, 10, 10, 0, 0) }
  let(:ticket) { ParkingTicket.new(vehicle, slot, entry_point, entry_time) }

  describe '.new' do
    it 'creates a ticket with the given vehicle, slot, entry point, and entry time' do
      expect(ticket.vehicle).to eq(vehicle)
      expect(ticket.slot).to eq(slot)
      expect(ticket.entry_point).to eq(entry_point)
      expect(ticket.entry_time).to eq(entry_time)
    end

    it 'uses current time as entry time if not provided' do
      allow(Time).to receive(:now).and_return(entry_time)
      current_time_ticket = ParkingTicket.new(vehicle, slot, entry_point)
      expect(current_time_ticket.entry_time).to eq(entry_time)
    end

    it 'initializes with nil exit time' do
      expect(ticket.exit_time).to be_nil
    end

    it 'raises an error if vehicle is nil' do
      expect { ParkingTicket.new(nil, slot, entry_point, entry_time) }.to raise_error(ArgumentError)
    end

    it 'raises an error if slot is nil' do
      expect do
        ParkingTicket.new(vehicle, nil, entry_point, entry_time)
      end.to raise_error(ArgumentError)
    end

    it 'raises an error if entry point is nil' do
      expect { ParkingTicket.new(vehicle, slot, nil, entry_time) }.to raise_error(ArgumentError)
    end
  end

  describe '#active?' do
    it 'returns true when exit time is nil' do
      expect(ticket.active?).to be true
    end

    it 'returns false when exit time is set' do
      ticket.exit_time = Time.new(2023, 6, 10, 14, 0, 0)
      expect(ticket.active?).to be false
    end
  end

  describe '#exit_time=' do
    it 'allows setting the exit time' do
      exit_time = Time.new(2023, 6, 10, 15, 30, 0)
      ticket.exit_time = exit_time
      expect(ticket.exit_time).to eq(exit_time)
    end

    it 'raises an error if exit time is before entry time' do
      exit_time = Time.new(2023, 6, 10, 9, 0, 0) # 1 hour before entry time
      expect { ticket.exit_time = exit_time }.to raise_error(ArgumentError)
    end

    it 'raises an error if exit time is nil' do
      expect { ticket.exit_time = nil }.to raise_error(ArgumentError)
    end

    it 'raises an error if exit time is not a Time object' do
      expect { ticket.exit_time = 'not a time' }.to raise_error(ArgumentError)
    end
  end

  describe '#duration_in_hours' do
    context 'when ticket is active' do
      it 'raises an error' do
        expect { ticket.duration_in_hours }.to raise_error(RuntimeError)
      end
    end

    context 'when ticket is closed' do
      before do
        ticket.exit_time = Time.new(2023, 6, 10, 14, 30, 0) # 4.5 hours after entry
      end

      it 'returns the duration in hours rounded up' do
        expect(ticket.duration_in_hours).to eq(5)
      end

      it 'returns 1 for durations less than an hour' do
        short_ticket = ParkingTicket.new(vehicle, slot, entry_point, entry_time)
        short_ticket.exit_time = entry_time + (30 * 60) # 30 minutes later
        expect(short_ticket.duration_in_hours).to eq(1)
      end

      it 'handles multi-day durations' do
        long_ticket = ParkingTicket.new(vehicle, slot, entry_point, entry_time)
        long_ticket.exit_time = entry_time + (50 * 3600) # 50 hours later
        expect(long_ticket.duration_in_hours).to eq(50)
      end
    end
  end

  describe '#duration_in_days_and_hours' do
    context 'when ticket is active' do
      it 'raises an error' do
        expect { ticket.duration_in_days_and_hours }.to raise_error(RuntimeError)
      end
    end

    context 'when ticket is closed' do
      it 'returns [0, hours] for less than 24 hours' do
        ticket.exit_time = entry_time + (10 * 3600) # 10 hours later
        expect(ticket.duration_in_days_and_hours).to eq([0, 10])
      end

      it 'returns [days, hours] for multi-day durations' do
        ticket.exit_time = entry_time + (50 * 3600) # 50 hours later
        expect(ticket.duration_in_days_and_hours).to eq([2, 2])
      end

      it 'returns [days, 0] for exact day durations' do
        ticket.exit_time = entry_time + (48 * 3600) # 48 hours (2 days) later
        expect(ticket.duration_in_days_and_hours).to eq([2, 0])
      end
    end
  end

  describe '#to_s' do
    it 'returns a string with ticket details' do
      expect(ticket.to_s).to include(vehicle.id)
      expect(ticket.to_s).to include(slot.id.to_s)
      expect(ticket.to_s).to include(entry_time.to_s)
    end

    it 'includes exit time when ticket is closed' do
      exit_time = Time.new(2023, 6, 10, 14, 0, 0)
      ticket.exit_time = exit_time
      expect(ticket.to_s).to include(exit_time.to_s)
    end
  end
end
