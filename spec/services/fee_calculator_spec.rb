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
  end

  # Hourly rate tests - beyond 3 hours
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
    end
  end

  # 24-hour rate tests
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
      end

      context 'in a large slot (LP)' do
        let(:vehicle) { LargeVehicle.new('L789') }
        let(:slot) { LargeParkingSlot.new(3, [5, 3, 4]) }

        it 'charges daily rate plus hourly rate for 24 hours + 4 hours' do
          entry_time = Time.new(2023, 6, 10, 10, 0, 0)
          exit_time = entry_time + (28 * 3600) # 28 hours later
          ticket = create_ticket(vehicle, slot, entry_point, entry_time, exit_time)

          # 1 day * 5000 + base rate 40 + 1 hour * 100 = 5140
          expect(calculator.calculate_fee(ticket)).to eq(5140)
        end
      end
    end
  end

  # Continuous rate tests - updated for the new scenarios
  describe 'continuous rate application' do
    # Scenario 1: Three parking sessions with gaps less than 1 hour - total 3 hours
    context 'with three consecutive tickets within continuous rate window' do
      let(:vehicle) { SmallVehicle.new('S123') }
      let(:small_slot) { SmallParkingSlot.new(1, [3, 5, 7]) }
      let(:entry_time) { Time.new(2023, 6, 10, 10, 0, 0) }

      it 'applies base rate only for three 1-hour sessions with 30-minute gaps' do
        # First parking: 1 hour
        first_exit_time = entry_time + (1 * 3600)
        first_ticket = create_ticket(vehicle, small_slot, entry_point, entry_time, first_exit_time)

        # Second parking: 30 minutes after first exit, for 1 hour
        second_entry_time = first_exit_time + (30 * 60)
        second_exit_time = second_entry_time + (1 * 3600)
        second_ticket = create_ticket(vehicle, small_slot, entry_point, second_entry_time, second_exit_time)

        # Third parking: 30 minutes after second exit, for 1 hour
        third_entry_time = second_exit_time + (30 * 60)
        third_exit_time = third_entry_time + (1 * 3600)
        third_ticket = create_ticket(vehicle, small_slot, entry_point, third_entry_time, third_exit_time)

        # Total actual parking time: 3 hours (1 + 1 + 1)
        # Expected fee: Base rate for 3 hours = 40 pesos
        expect(calculator.calculate_fee_with_continuous_rate(first_ticket, second_ticket, third_ticket)).to eq(40)
      end
    end

    # Scenario 2: Two parking sessions with gap more than 1 hour - separate rates
    context 'with vehicle returning after more than 1 hour' do
      let(:vehicle) { SmallVehicle.new('S123') }
      let(:small_slot) { SmallParkingSlot.new(1, [3, 5, 7]) }
      let(:entry_time) { Time.new(2023, 6, 10, 10, 0, 0) }

      it 'calculates separate fees for two 1-hour sessions with a 2-hour gap' do
        # First parking: 1 hour
        first_exit_time = entry_time + (1 * 3600)
        first_ticket = create_ticket(vehicle, small_slot, entry_point, entry_time, first_exit_time)

        # Second parking: 2 hours after first exit, for 1 hour
        second_entry_time = first_exit_time + (2 * 3600)
        second_exit_time = second_entry_time + (1 * 3600)
        second_ticket = create_ticket(vehicle, small_slot, entry_point, second_entry_time, second_exit_time)

        # Since gap is > 1 hour, should calculate fees separately
        # First ticket: 1 hour = Base rate (40)
        # Second ticket: 1 hour = Base rate (40)
        # Total: 40 + 40 = 80 pesos
        fee = calculator.calculate_fee_with_continuous_rate(first_ticket, second_ticket)
        expect(fee).to eq(80)

        # Check individual fees to ensure they're calculated separately
        expect(calculator.calculate_fee(first_ticket)).to eq(40)
        expect(calculator.calculate_fee(second_ticket)).to eq(40)
      end
    end

    # Scenario 3: Parking in different slot types with continuous rate
    context 'with vehicle moving to different slot types' do
      let(:vehicle) { SmallVehicle.new('S123') }
      let(:small_slot) { SmallParkingSlot.new(1, [3, 5, 7]) }
      let(:large_slot) { LargeParkingSlot.new(3, [5, 1, 6]) }
      let(:entry_time) { Time.new(2023, 6, 10, 10, 0, 0) }

      it 'charge correct rate when parking in small slot then large slot' do
        # First parking: 1 hour in small slot
        first_exit_time = entry_time + (1 * 3600)
        first_ticket = create_ticket(vehicle, small_slot, entry_point, entry_time, first_exit_time)

        # Second parking: 30 minutes after first exit, for 3 hours in large slot
        second_entry_time = first_exit_time + (30 * 60)
        second_exit_time = second_entry_time + (3 * 3600)
        second_ticket = create_ticket(vehicle, large_slot, entry_point, second_entry_time, second_exit_time)

        # Total actual parking time: 4 hours (1 in small slot + 3 in large slot)
        # First 3 hours covered by base rate: 40 pesos
        # 1 remaining hour charged at large slot rate: 100 pesos
        # Total fee: 40 + 100 = 140 pesos
        expect(calculator.calculate_fee_with_continuous_rate(first_ticket, second_ticket)).to eq(140)
      end

      it 'charge correct rate when parking in large slot then small slot' do
        # First parking: 1 hour in large slot
        first_exit_time = entry_time + (1 * 3600)
        first_ticket = create_ticket(vehicle, large_slot, entry_point, entry_time, first_exit_time)

        # Second parking: 30 minutes after first exit, for 3 hours in small slot
        second_entry_time = first_exit_time + (30 * 60)
        second_exit_time = second_entry_time + (3 * 3600)
        second_ticket = create_ticket(vehicle, small_slot, entry_point, second_entry_time, second_exit_time)

        # Total actual parking time: 4 hours (1 in large slot + 3 in small slot)
        # First 3 hours covered by base rate: 40 pesos
        # Here the 1 hour in large slot should be applied to excess first
        # 1 remaining hour charged at small slot rate: 20 pesos
        # Total fee: 40 + 20 = 60 pesos
        expect(calculator.calculate_fee_with_continuous_rate(first_ticket, second_ticket)).to eq(60)
      end
    end

    # Edge cases for continuous rate
    context 'with edge cases' do
      let(:vehicle) { SmallVehicle.new('S123') }
      let(:small_slot) { SmallParkingSlot.new(1, [3, 5, 7]) }
      let(:medium_slot) { MediumParkingSlot.new(2, [4, 2, 6]) }
      let(:large_slot) { LargeParkingSlot.new(3, [5, 1, 6]) }
      let(:entry_time) { Time.new(2023, 6, 10, 10, 0, 0) }

      it 'handles exact 1-hour gap correctly' do
        # First parking: 2 hours
        first_exit_time = entry_time + (2 * 3600)
        first_ticket = create_ticket(vehicle, small_slot, entry_point, entry_time, first_exit_time)

        # Second parking: Exactly 1 hour after first exit, for 2 hours
        second_entry_time = first_exit_time + (1 * 3600)
        second_exit_time = second_entry_time + (2 * 3600)
        second_ticket = create_ticket(vehicle, small_slot, entry_point, second_entry_time, second_exit_time)

        # Total actual parking time: 4 hours (2 + 2)
        # First 3 hours covered by base rate: 40 pesos
        # 1 remaining hour charged at small slot rate: 20 pesos
        # Total fee: 40 + 20 = 60 pesos
        expect(calculator.calculate_fee_with_continuous_rate(first_ticket, second_ticket)).to eq(60)
      end

      it 'handles mixed slot types with exact base rate hours' do
        # First parking: 1 hour in small slot
        first_exit_time = entry_time + (1 * 3600)
        first_ticket = create_ticket(vehicle, small_slot, entry_point, entry_time, first_exit_time)

        # Second parking: 30 minutes after first exit, for 1 hour in medium slot
        second_entry_time = first_exit_time + (30 * 60)
        second_exit_time = second_entry_time + (1 * 3600)
        second_ticket = create_ticket(vehicle, medium_slot, entry_point, second_entry_time, second_exit_time)

        # Third parking: 30 minutes after second exit, for 1 hour in large slot
        third_entry_time = second_exit_time + (30 * 60)
        third_exit_time = third_entry_time + (1 * 3600)
        third_ticket = create_ticket(vehicle, large_slot, entry_point, third_entry_time, third_exit_time)

        # Total actual parking time: 3 hours (1 + 1 + 1)
        # Exactly 3 hours, so just base rate: 40 pesos
        expect(calculator.calculate_fee_with_continuous_rate(first_ticket, second_ticket, third_ticket)).to eq(40)
      end

      it 'handles mixed slot types exceeding base rate' do
        # First parking: 2 hours in small slot
        first_exit_time = entry_time + (2 * 3600)
        first_ticket = create_ticket(vehicle, small_slot, entry_point, entry_time, first_exit_time)

        # Second parking: 30 minutes after first exit, for 1 hour in medium slot
        second_entry_time = first_exit_time + (30 * 60)
        second_exit_time = second_entry_time + (1 * 3600)
        second_ticket = create_ticket(vehicle, medium_slot, entry_point, second_entry_time, second_exit_time)

        # Third parking: 30 minutes after second exit, for 2 hours in large slot
        third_entry_time = second_exit_time + (30 * 60)
        third_exit_time = third_entry_time + (2 * 3600)
        third_ticket = create_ticket(vehicle, large_slot, entry_point, third_entry_time, third_exit_time)

        # Total actual parking time: 5 hours (2 + 1 + 2)
        # First 3 hours covered by base rate: 40 pesos
        # Remaining 2 hours should be charged at higher rates first
        # 2 hours at large slot rate: 2 * 100 = 200 pesos
        # Total fee: 40 + 200 = 240 pesos
        expect(calculator.calculate_fee_with_continuous_rate(first_ticket, second_ticket, third_ticket)).to eq(240)
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
