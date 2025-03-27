# frozen_string_literal: true

require 'spec_helper'
require 'models/parking_complex'
require 'models/entry_point'
require 'models/small_parking_slot'
require 'models/medium_parking_slot'
require 'models/large_parking_slot'
require 'models/small_vehicle'
require 'models/medium_vehicle'
require 'models/large_vehicle'
require 'services/parking_allocator'
require 'services/fee_calculator'
require 'services/vehicle_tracker'
require 'repositories/in_memory_repository'

RSpec.describe 'Fee Calculation Integration' do
  # Create a complete parking system
  let(:entry_points) do
    [
      EntryPoint.new(0),
      EntryPoint.new(1),
      EntryPoint.new(2)
    ]
  end

  let(:parking_slots) do
    [
      SmallParkingSlot.new(1, [1, 5, 8]),
      MediumParkingSlot.new(2, [2, 6, 9]),
      LargeParkingSlot.new(3, [3, 7, 10])
    ]
  end

  let(:repository) { InMemoryRepository.new }
  let(:allocator) { ParkingAllocator.new }
  let(:calculator) { FeeCalculator.new }
  let(:tracker) { VehicleTracker.new }

  let(:complex) do
    ParkingComplex.new(
      entry_points,
      parking_slots,
      repository: repository,
      allocator: allocator,
      calculator: calculator,
      tracker: tracker
    )
  end

  # Base time for consistent testing
  let(:base_time) { Time.new(2023, 6, 10, 10, 0, 0) }

  describe 'Base rate scenarios' do
    before do
      # Fix the entry time
      allow(Time).to receive(:now).and_return(base_time)
    end

    it 'charges flat rate of 40 pesos for up to 3 hours in any slot type' do
      # Park vehicles in different slot types
      small_vehicle = SmallVehicle.new('SV-001')
      medium_vehicle = MediumVehicle.new('MV-001')
      large_vehicle = LargeVehicle.new('LV-001')

      complex.park(small_vehicle, entry_points[0]) # Small slot
      complex.park(medium_vehicle, entry_points[0]) # Medium slot
      complex.park(large_vehicle, entry_points[0]) # Large slot

      # Advance 2 hours (within base rate)
      exit_time = base_time + (2 * 3600)
      allow(Time).to receive(:now).and_return(exit_time)

      # Unpark the vehicles
      small_result = complex.unpark(small_vehicle)
      medium_result = complex.unpark(medium_vehicle)
      large_result = complex.unpark(large_vehicle)

      # Verify all fees are the base rate
      expect(small_result.fee).to eq(40) # Small slot
      expect(medium_result.fee).to eq(40) # Medium slot
      expect(large_result.fee).to eq(40) # Large slot
    end

    it 'charges flat rate for exactly 3 hours in any slot type' do
      # Park vehicles in different slot types
      small_vehicle = SmallVehicle.new('SV-002')
      medium_vehicle = MediumVehicle.new('MV-002')
      large_vehicle = LargeVehicle.new('LV-002')

      complex.park(small_vehicle, entry_points[0])
      complex.park(medium_vehicle, entry_points[0])
      complex.park(large_vehicle, entry_points[0])

      # Advance exactly 3 hours
      exit_time = base_time + (3 * 3600)
      allow(Time).to receive(:now).and_return(exit_time)

      # Unpark the vehicles
      small_result = complex.unpark(small_vehicle)
      medium_result = complex.unpark(medium_vehicle)
      large_result = complex.unpark(large_vehicle)

      # Verify all fees are the base rate
      expect(small_result.fee).to eq(40)
      expect(medium_result.fee).to eq(40)
      expect(large_result.fee).to eq(40)
    end
  end

  describe 'Hourly rate scenarios' do
    before do
      # Fix the entry time
      allow(Time).to receive(:now).and_return(base_time)
    end

    it 'charges correct hourly rates for durations beyond the base rate' do
      # Park vehicles in different slot types
      small_vehicle = SmallVehicle.new('SV-003')
      medium_vehicle = MediumVehicle.new('MV-003')
      large_vehicle = LargeVehicle.new('LV-003')

      complex.park(small_vehicle, entry_points[0]) # Small slot
      complex.park(medium_vehicle, entry_points[0]) # Medium slot
      complex.park(large_vehicle, entry_points[0]) # Large slot

      # Advance 4 hours (1 hour beyond base rate)
      exit_time = base_time + (4 * 3600)
      allow(Time).to receive(:now).and_return(exit_time)

      # Unpark the vehicles
      small_result = complex.unpark(small_vehicle)
      medium_result = complex.unpark(medium_vehicle)
      large_result = complex.unpark(large_vehicle)

      # Verify fees: base rate + hourly rate
      # Small slot: 40 + 1*20 = 60
      expect(small_result.fee).to eq(60)

      # Medium slot: 40 + 1*60 = 100
      expect(medium_result.fee).to eq(100)

      # Large slot: 40 + 1*100 = 140
      expect(large_result.fee).to eq(140)
    end

    it 'correctly handles partial hours (rounding up)' do
      # Park a vehicle
      small_vehicle = SmallVehicle.new('SV-004')
      complex.park(small_vehicle, entry_points[0])

      # Advance 3.5 hours (0.5 hour beyond base rate)
      exit_time = base_time + (3.5 * 3600)
      allow(Time).to receive(:now).and_return(exit_time)

      # Unpark the vehicle
      result = complex.unpark(small_vehicle)

      # Verify fee: 3.5 hours rounds up to 4 hours
      # Base rate (40) + 1 hour at small slot rate (20) = 60
      expect(result.fee).to eq(60)
    end

    it 'bases hourly rate on slot type, not vehicle type' do
      # Park a small vehicle in a large slot
      small_vehicle = SmallVehicle.new('SV-005')

      # Force allocation to a large slot by occupying small and medium slots
      parking_slots[0].occupy # Occupy small slot
      parking_slots[1].occupy # Occupy medium slot

      # Park the small vehicle (should get large slot)
      complex.park(small_vehicle, entry_points[0])

      # Advance 4 hours
      exit_time = base_time + (4 * 3600)
      allow(Time).to receive(:now).and_return(exit_time)

      # Unpark the vehicle
      result = complex.unpark(small_vehicle)

      # Verify fee based on large slot rate
      # Base rate (40) + 1 hour at large slot rate (100) = 140
      expect(result.fee).to eq(140)
    end
  end

  describe 'Daily rate scenarios' do
    before do
      # Fix the entry time
      allow(Time).to receive(:now).and_return(base_time)
    end

    it 'charges flat rate of 5000 pesos per day' do
      # Park a vehicle
      small_vehicle = SmallVehicle.new('SV-006')
      complex.park(small_vehicle, entry_points[0])

      # Advance exactly 24 hours
      exit_time = base_time + (24 * 3600)
      allow(Time).to receive(:now).and_return(exit_time)

      # Unpark the vehicle
      result = complex.unpark(small_vehicle)

      # Verify fee: 1 day = 5000 pesos
      expect(result.fee).to eq(5000)
    end

    # Create a separate test for the 48-hour case
    it 'charges daily rate for multi-day stays' do
      # Park a vehicle for 48 hours
      another_vehicle = SmallVehicle.new('SV-007')
      complex.park(another_vehicle, entry_points[0])

      # Advance exactly 48 hours (2 days)
      long_exit_time = base_time + (48 * 3600)
      allow(Time).to receive(:now).and_return(long_exit_time)

      # Unpark the vehicle
      another_result = complex.unpark(another_vehicle)

      expect(another_result.fee).to eq(10_000)

      # Output the actual fee for debugging
      puts "Actual fee for 48-hour stay: #{another_result.fee}"
    end

    it 'charges daily rate plus base rate for remainder within 3 hours' do
      # Park a vehicle
      small_vehicle = SmallVehicle.new('SV-008')
      complex.park(small_vehicle, entry_points[0])

      # Advance 27 hours (1 day + 3 hours)
      exit_time = base_time + (27 * 3600)
      allow(Time).to receive(:now).and_return(exit_time)

      # Unpark the vehicle
      result = complex.unpark(small_vehicle)

      # Verify fee: 1 day (5000) + base rate for 3 hours (40) = 5040
      expect(result.fee).to eq(5040)
    end

    it 'charges daily rate plus hourly rate for remainder beyond 3 hours' do
      # Park a vehicle
      small_vehicle = SmallVehicle.new('SV-009')
      complex.park(small_vehicle, entry_points[0])

      # Advance 28 hours (1 day + 4 hours)
      exit_time = base_time + (28 * 3600)
      allow(Time).to receive(:now).and_return(exit_time)

      # Unpark the vehicle
      result = complex.unpark(small_vehicle)

      # Verify fee: 1 day (5000) + base rate (40) + 1 hour at small slot rate (20) = 5060
      expect(result.fee).to eq(5060)
    end
  end

  describe 'Continuous rate scenarios' do
    before do
      # Fix the entry time
      allow(Time).to receive(:now).and_return(base_time)
    end

    it 'applies continuous rate for vehicle returning within 1 hour' do
      # Park a vehicle
      small_vehicle = SmallVehicle.new('SV-010')
      complex.park(small_vehicle, entry_points[0])

      # Advance 2 hours
      first_exit_time = base_time + (2 * 3600)
      allow(Time).to receive(:now).and_return(first_exit_time)

      # Unpark the vehicle
      first_result = complex.unpark(small_vehicle)
      expect(first_result.fee).to eq(40) # Base rate

      # Advance 30 minutes (within continuous rate window)
      return_time = first_exit_time + (30 * 60)
      allow(Time).to receive(:now).and_return(return_time)

      # Park the vehicle again
      second_ticket = complex.park(small_vehicle, entry_points[0])
      expect(second_ticket.previous_ticket).to eq(first_result) # Verify link

      # Advance 3 more hours
      final_exit_time = return_time + (3 * 3600)
      allow(Time).to receive(:now).and_return(final_exit_time)

      # Unpark the vehicle
      second_result = complex.unpark(small_vehicle)

      # Calculate expected fee based on your implementation
      # Total time: 2 hours + 3 hours = 5 hours
      # Base rate (40) for the first 3 hours + extra 2 hours at hourly rate (2 * 20) = 80
      expect(second_result.fee).to eq(80)
    end

    it 'does not apply continuous rate if vehicle returns after 1 hour' do
      # Park a vehicle
      small_vehicle = SmallVehicle.new('SV-012')
      complex.park(small_vehicle, entry_points[0])

      # Advance 2 hours
      first_exit_time = base_time + (2 * 3600)
      allow(Time).to receive(:now).and_return(first_exit_time)

      # Unpark the vehicle
      first_result = complex.unpark(small_vehicle)

      # Verify first parking fee (2 hours = base rate)
      expect(first_result.fee).to eq(40)

      # Advance 65 minutes (outside continuous rate window)
      return_time = first_exit_time + (65 * 60)
      allow(Time).to receive(:now).and_return(return_time)

      # Park the vehicle again
      second_ticket = complex.park(small_vehicle, entry_points[0])

      # Verify no continuous rate link
      expect(second_ticket.previous_ticket).to be_nil

      # Advance 3 more hours
      final_exit_time = return_time + (3 * 3600)
      allow(Time).to receive(:now).and_return(final_exit_time)

      # Unpark the vehicle
      second_result = complex.unpark(small_vehicle)

      # Verify second parking fee (3 hours = base rate)
      expect(second_result.fee).to eq(40)
    end
  end

  describe 'Edge cases' do
    before do
      # Fix the entry time
      allow(Time).to receive(:now).and_return(base_time)
    end

    it 'handles very short stays correctly' do
      # Park a vehicle
      small_vehicle = SmallVehicle.new('SV-013')
      complex.park(small_vehicle, entry_points[0])

      # Advance just 15 minutes
      exit_time = base_time + (15 * 60)
      allow(Time).to receive(:now).and_return(exit_time)

      # Unpark the vehicle
      result = complex.unpark(small_vehicle)

      # Verify fee (minimum is base rate)
      expect(result.fee).to eq(40)
    end

    it 'handles 3-hour boundary case correctly' do
      # Park a vehicle for exactly 3 hours
      vehicle = SmallVehicle.new('SV-BOUNDARY-3H')
      complex.park(vehicle, entry_points[0])

      # Advance by 3 hours
      exit_time = base_time + (3 * 3600)
      allow(Time).to receive(:now).and_return(exit_time)

      # Unpark the vehicle
      result = complex.unpark(vehicle)

      # Expect base rate
      expect(result.fee).to eq(40)
    end

    it 'handles just-over-3-hour case correctly' do
      # Park a vehicle for just over 3 hours
      vehicle = SmallVehicle.new('SV-BOUNDARY-3H-PLUS')
      complex.park(vehicle, entry_points[0])

      # Advance by 3 hours + 1 second
      exit_time = base_time + (3 * 3600) + 1
      allow(Time).to receive(:now).and_return(exit_time)

      # Unpark the vehicle
      result = complex.unpark(vehicle)

      expect(result.fee).to eq(60)

      # Output the actual fee for debugging
      puts "Actual fee for 3 hours + 1 second: #{result.fee}"
    end

    it 'handles 24-hour boundary case correctly' do
      # Park a vehicle for exactly 24 hours
      vehicle = SmallVehicle.new('SV-BOUNDARY-24H')
      complex.park(vehicle, entry_points[0])

      # Advance by 24 hours
      exit_time = base_time + (24 * 3600)
      allow(Time).to receive(:now).and_return(exit_time)

      # Unpark the vehicle
      result = complex.unpark(vehicle)

      # Expect daily rate
      expect(result.fee).to eq(5000)
    end

    it 'handles just-over-24-hour case correctly' do
      # Park a vehicle for just over 24 hours
      vehicle = SmallVehicle.new('SV-BOUNDARY-24H-PLUS')
      complex.park(vehicle, entry_points[0])

      # Advance by 24 hours + 1 second
      exit_time = base_time + (24 * 3600) + 1
      allow(Time).to receive(:now).and_return(exit_time)

      # Unpark the vehicle
      result = complex.unpark(vehicle)

      expect(result.fee).to eq(5040)

      # Output the actual fee for debugging
      puts "Actual fee for 24 hours + 1 second: #{result.fee}"
    end
  end
end
