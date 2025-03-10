# frozen_string_literal: true

require 'spec_helper'
require 'services/fee_calculator'
require 'models/parking_ticket'
require 'models/small_vehicle'
require 'models/medium_vehicle'
require 'models/large_vehicle'
require 'models/small_parking_slot'
require 'models/medium_parking_slot'
require 'models/large_parking_slot'
require 'models/entry_point'

RSpec.describe FeeCalculator do
  let(:entry_point) { EntryPoint.new(0) }
  let(:calculator) { FeeCalculator.new }

  # Base rate tests - 40 pesos for first 3 hours
  describe 'base rate calculation' do
    context 'with small slot (SP)' do
      let(:vehicle) { SmallVehicle.new('S123') }
      let(:slot) { SmallParkingSlot.new(1, [3, 5, 7]) }

      it 'charges flat rate of 40 pesos for exactly 3 hours' do
        entry_time = Time.new(2023, 6, 10, 10, 0, 0)
        exit_time = entry_time + (3 * 3600) # 3 hours later
        ticket = create_ticket(vehicle, slot, entry_point, entry_time, exit_time)

        expect(calculator.calculate_fee(ticket)).to eq(40)
      end

      it 'charges flat rate of 40 pesos for less than 3 hours' do
        entry_time = Time.new(2023, 6, 10, 10, 0, 0)
        exit_time = entry_time + (2 * 3600) # 2 hours later
        ticket = create_ticket(vehicle, slot, entry_point, entry_time, exit_time)

        expect(calculator.calculate_fee(ticket)).to eq(40)
      end

      it 'charges flat rate of 40 pesos for partial hour (less than 3 hours)' do
        entry_time = Time.new(2023, 6, 10, 10, 0, 0)
        exit_time = entry_time + (2.5 * 3600) # 2.5 hours later
        ticket = create_ticket(vehicle, slot, entry_point, entry_time, exit_time)

        expect(calculator.calculate_fee(ticket)).to eq(40)
      end
    end

    context 'with medium slot (MP)' do
      let(:vehicle) { MediumVehicle.new('M456') }
      let(:slot) { MediumParkingSlot.new(2, [4, 2, 6]) }

      it 'charges flat rate of 40 pesos for less than 3 hours' do
        entry_time = Time.new(2023, 6, 10, 10, 0, 0)
        exit_time = entry_time + (2 * 3600) # 2 hours later
        ticket = create_ticket(vehicle, slot, entry_point, entry_time, exit_time)

        expect(calculator.calculate_fee(ticket)).to eq(40)
      end
    end

    context 'with large slot (LP)' do
      let(:vehicle) { LargeVehicle.new('L789') }
      let(:slot) { LargeParkingSlot.new(3, [5, 3, 4]) }

      it 'charges flat rate of 40 pesos for less than 3 hours' do
        entry_time = Time.new(2023, 6, 10, 10, 0, 0)
        exit_time = entry_time + (2 * 3600) # 2 hours later
        ticket = create_ticket(vehicle, slot, entry_point, entry_time, exit_time)

        expect(calculator.calculate_fee(ticket)).to eq(40)
      end
    end

    context 'with small vehicle in different slot types' do
      let(:vehicle) { SmallVehicle.new('S123') }
      let(:small_slot) { SmallParkingSlot.new(1, [3, 5, 7]) }
      let(:medium_slot) { MediumParkingSlot.new(2, [4, 2, 6]) }
      let(:large_slot) { LargeParkingSlot.new(3, [5, 3, 4]) }

      it 'charges the same base rate regardless of slot type' do
        entry_time = Time.new(2023, 6, 10, 10, 0, 0)
        exit_time = entry_time + (2 * 3600) # 2 hours later

        small_slot_ticket = create_ticket(vehicle, small_slot, entry_point, entry_time, exit_time)
        medium_slot_ticket = create_ticket(vehicle, medium_slot, entry_point, entry_time, exit_time)
        large_slot_ticket = create_ticket(vehicle, large_slot, entry_point, entry_time, exit_time)

        expect(calculator.calculate_fee(small_slot_ticket)).to eq(40)
        expect(calculator.calculate_fee(medium_slot_ticket)).to eq(40)
        expect(calculator.calculate_fee(large_slot_ticket)).to eq(40)
      end
    end

    context 'with very short stays' do
      let(:vehicle) { SmallVehicle.new('S123') }
      let(:slot) { SmallParkingSlot.new(1, [3, 5, 7]) }

      it 'charges minimum flat rate for just a few minutes' do
        entry_time = Time.new(2023, 6, 10, 10, 0, 0)
        exit_time = entry_time + (15 * 60) # 15 minutes later
        ticket = create_ticket(vehicle, slot, entry_point, entry_time, exit_time)

        expect(calculator.calculate_fee(ticket)).to eq(40)
      end
    end
  end

  describe 'hourly rate calculation' do
    context 'with small slot (SP)' do
      let(:vehicle) { SmallVehicle.new('S123') }
      let(:slot) { SmallParkingSlot.new(1, [3, 5, 7]) }

      it 'charges base rate + 20 pesos for 4 hours (1 hour beyond base rate)' do
        entry_time = Time.new(2023, 6, 10, 10, 0, 0)
        exit_time = entry_time + (4 * 3600) # 4 hours later
        ticket = create_ticket(vehicle, slot, entry_point, entry_time, exit_time)

        # 40 (base) + 1 * 20 (hourly rate for small slot)
        expect(calculator.calculate_fee(ticket)).to eq(60)
      end

      it 'charges base rate + 40 pesos for 5 hours (2 hours beyond base rate)' do
        entry_time = Time.new(2023, 6, 10, 10, 0, 0)
        exit_time = entry_time + (5 * 3600) # 5 hours later
        ticket = create_ticket(vehicle, slot, entry_point, entry_time, exit_time)

        # 40 (base) + 2 * 20 (hourly rate for small slot)
        expect(calculator.calculate_fee(ticket)).to eq(80)
      end

      it 'charges base rate + hourly rate for partial hour (rounds up)' do
        entry_time = Time.new(2023, 6, 10, 10, 0, 0)
        exit_time = entry_time + (3.5 * 3600) # 3.5 hours later
        ticket = create_ticket(vehicle, slot, entry_point, entry_time, exit_time)

        # Rounds up to 4 hours: 40 (base) + 1 * 20 (hourly rate for small slot)
        expect(calculator.calculate_fee(ticket)).to eq(60)
      end
    end

    context 'with medium slot (MP)' do
      let(:vehicle) { MediumVehicle.new('M456') }
      let(:slot) { MediumParkingSlot.new(2, [4, 2, 6]) }

      it 'charges base rate + 60 pesos for 4 hours (1 hour beyond base rate)' do
        entry_time = Time.new(2023, 6, 10, 10, 0, 0)
        exit_time = entry_time + (4 * 3600) # 4 hours later
        ticket = create_ticket(vehicle, slot, entry_point, entry_time, exit_time)

        # 40 (base) + 1 * 60 (hourly rate for medium slot)
        expect(calculator.calculate_fee(ticket)).to eq(100)
      end

      it 'charges base rate + 120 pesos for 5 hours (2 hours beyond base rate)' do
        entry_time = Time.new(2023, 6, 10, 10, 0, 0)
        exit_time = entry_time + (5 * 3600) # 5 hours later
        ticket = create_ticket(vehicle, slot, entry_point, entry_time, exit_time)

        # 40 (base) + 2 * 60 (hourly rate for medium slot)
        expect(calculator.calculate_fee(ticket)).to eq(160)
      end
    end

    context 'with large slot (LP)' do
      let(:vehicle) { LargeVehicle.new('L789') }
      let(:slot) { LargeParkingSlot.new(3, [5, 3, 4]) }

      it 'charges base rate + 100 pesos for 4 hours (1 hour beyond base rate)' do
        entry_time = Time.new(2023, 6, 10, 10, 0, 0)
        exit_time = entry_time + (4 * 3600) # 4 hours later
        ticket = create_ticket(vehicle, slot, entry_point, entry_time, exit_time)

        # 40 (base) + 1 * 100 (hourly rate for large slot)
        expect(calculator.calculate_fee(ticket)).to eq(140)
      end

      it 'charges base rate + 200 pesos for 5 hours (2 hours beyond base rate)' do
        entry_time = Time.new(2023, 6, 10, 10, 0, 0)
        exit_time = entry_time + (5 * 3600) # 5 hours later
        ticket = create_ticket(vehicle, slot, entry_point, entry_time, exit_time)

        # 40 (base) + 2 * 100 (hourly rate for large slot)
        expect(calculator.calculate_fee(ticket)).to eq(240)
      end
    end

    context 'with different vehicle types in the same slot type' do
      let(:small_vehicle) { SmallVehicle.new('S123') }
      let(:medium_vehicle) { MediumVehicle.new('M456') }
      let(:large_slot) { LargeParkingSlot.new(3, [5, 3, 4]) }

      it 'charges based on slot type, not vehicle type' do
        entry_time = Time.new(2023, 6, 10, 10, 0, 0)
        exit_time = entry_time + (4 * 3600) # 4 hours later

        small_vehicle_ticket = create_ticket(small_vehicle, large_slot, entry_point, entry_time, exit_time)
        medium_vehicle_ticket = create_ticket(medium_vehicle, large_slot, entry_point, entry_time, exit_time)

        # Both should be charged based on large slot rate
        # 40 (base) + 1 * 100 (hourly rate for large slot)
        expect(calculator.calculate_fee(small_vehicle_ticket)).to eq(140)
        expect(calculator.calculate_fee(medium_vehicle_ticket)).to eq(140)
      end
    end

    context 'with edge cases for hourly rate calculation' do
      let(:vehicle) { SmallVehicle.new('S123') }
      let(:slot) { SmallParkingSlot.new(1, [3, 5, 7]) }

      it 'rounds to the nearest hour for partial hours beyond the base rate' do
        entry_time = Time.new(2023, 6, 10, 10, 0, 0)
        exit_time = entry_time + (4.2 * 3600) # 4 hours and 12 minutes later
        ticket = create_ticket(vehicle, slot, entry_point, entry_time, exit_time)

        # Rounds up to 5 hours: 40 (base) + 2 * 20 (hourly rate for small slot)
        expect(calculator.calculate_fee(ticket)).to eq(80)
      end

      it 'handles exactly at the hour boundary correctly' do
        entry_time = Time.new(2023, 6, 10, 10, 0, 0)
        exit_time = entry_time + (5 * 3600) # Exactly 5 hours later
        ticket = create_ticket(vehicle, slot, entry_point, entry_time, exit_time)

        # 40 (base) + 2 * 20 (hourly rate for small slot)
        expect(calculator.calculate_fee(ticket)).to eq(80)
      end
    end
  end

  describe '24-hour rate calculation' do
    context 'with exactly 24 hours' do
      let(:vehicle) { SmallVehicle.new('S123') }
      let(:slot) { SmallParkingSlot.new(1, [3, 5, 7]) }

      it 'charges 5000 pesos flat rate for 24 hours' do
        entry_time = Time.new(2023, 6, 10, 10, 0, 0)
        exit_time = entry_time + (24 * 3600) # Exactly 24 hours later
        ticket = create_ticket(vehicle, slot, entry_point, entry_time, exit_time)

        expect(calculator.calculate_fee(ticket)).to eq(5000)
      end
    end

    context 'with multiple complete 24-hour periods' do
      let(:vehicle) { SmallVehicle.new('S123') }
      let(:slot) { SmallParkingSlot.new(1, [3, 5, 7]) }

      it 'charges 10000 pesos for 48 hours (2 complete days)' do
        entry_time = Time.new(2023, 6, 10, 10, 0, 0)
        exit_time = entry_time + (48 * 3600) # 48 hours later
        ticket = create_ticket(vehicle, slot, entry_point, entry_time, exit_time)

        # 2 days * 5000 = 10000
        expect(calculator.calculate_fee(ticket)).to eq(10_000)
      end

      it 'charges 15000 pesos for 72 hours (3 complete days)' do
        entry_time = Time.new(2023, 6, 10, 10, 0, 0)
        exit_time = entry_time + (72 * 3600) # 72 hours later
        ticket = create_ticket(vehicle, slot, entry_point, entry_time, exit_time)

        # 3 days * 5000 = 15000
        expect(calculator.calculate_fee(ticket)).to eq(15_000)
      end
    end

    context 'with 24-hour periods plus remainder hours' do
      context 'in a small slot (SP)' do
        let(:vehicle) { SmallVehicle.new('S123') }
        let(:slot) { SmallParkingSlot.new(1, [3, 5, 7]) }

        it 'charges daily rate plus base rate for 24 hours + 3 hours' do
          entry_time = Time.new(2023, 6, 10, 10, 0, 0)
          exit_time = entry_time + (27 * 3600) # 27 hours later
          ticket = create_ticket(vehicle, slot, entry_point, entry_time, exit_time)

          # 1 day * 5000 + base rate 40 = 5040
          expect(calculator.calculate_fee(ticket)).to eq(5040)
        end

        it 'charges daily rate plus hourly rate for 24 hours + 4 hours' do
          entry_time = Time.new(2023, 6, 10, 10, 0, 0)
          exit_time = entry_time + (28 * 3600) # 28 hours later
          ticket = create_ticket(vehicle, slot, entry_point, entry_time, exit_time)

          # 1 day * 5000 + base rate 40 + 1 hour * 20 = 5060
          expect(calculator.calculate_fee(ticket)).to eq(5060)
        end
      end

      context 'in a medium slot (MP)' do
        let(:vehicle) { MediumVehicle.new('M456') }
        let(:slot) { MediumParkingSlot.new(2, [4, 2, 6]) }

        it 'charges daily rate plus hourly rate for 48 hours + 5 hours' do
          entry_time = Time.new(2023, 6, 10, 10, 0, 0)
          exit_time = entry_time + (53 * 3600) # 53 hours later
          ticket = create_ticket(vehicle, slot, entry_point, entry_time, exit_time)

          # 2 days * 5000 + base rate 40 + 2 hours * 60 = 10160
          expect(calculator.calculate_fee(ticket)).to eq(10_160)
        end
      end

      context 'in a large slot (LP)' do
        let(:vehicle) { LargeVehicle.new('L789') }
        let(:slot) { LargeParkingSlot.new(3, [5, 3, 4]) }

        it 'charges daily rate plus hourly rate for 72 hours + 6 hours' do
          entry_time = Time.new(2023, 6, 10, 10, 0, 0)
          exit_time = entry_time + (78 * 3600) # 78 hours later
          ticket = create_ticket(vehicle, slot, entry_point, entry_time, exit_time)

          # 3 days * 5000 + base rate 40 + 3 hours * 100 = 15340
          expect(calculator.calculate_fee(ticket)).to eq(15_340)
        end
      end
    end

    context 'with edge cases for 24-hour rate calculation' do
      let(:vehicle) { SmallVehicle.new('S123') }
      let(:slot) { SmallParkingSlot.new(1, [3, 5, 7]) }

      it 'handles just under 24 hours correctly (hourly rate applies)' do
        entry_time = Time.new(2023, 6, 10, 10, 0, 0)
        exit_time = entry_time + (23.9 * 3600) # 23.9 hours later - rounds up to 24
        ticket = create_ticket(vehicle, slot, entry_point, entry_time, exit_time)

        # Exactly 24 hours flat rate
        expect(calculator.calculate_fee(ticket)).to eq(5000)
      end

      it 'handles just over 24 hours correctly (daily + base rate applies)' do
        entry_time = Time.new(2023, 6, 10, 10, 0, 0)
        exit_time = entry_time + (24.1 * 3600) # 24.1 hours later - rounds up to 25
        ticket = create_ticket(vehicle, slot, entry_point, entry_time, exit_time)

        # 1 day * 5000 + base rate 40 = 5040
        expect(calculator.calculate_fee(ticket)).to eq(5040)
      end

      it 'handles very long durations correctly' do
        entry_time = Time.new(2023, 6, 10, 10, 0, 0)
        exit_time = entry_time + (240 * 3600) # 240 hours (10 days) later
        ticket = create_ticket(vehicle, slot, entry_point, entry_time, exit_time)

        # 10 days * 5000 = 50000
        expect(calculator.calculate_fee(ticket)).to eq(50_000)
      end
    end
  end

  # Helper method to create a ticket with entry and exit times
  def create_ticket(vehicle, slot, entry_point, entry_time, exit_time)
    ticket = ParkingTicket.new(vehicle, slot, entry_point, entry_time)
    ticket.exit_time = exit_time
    ticket
  end
end
