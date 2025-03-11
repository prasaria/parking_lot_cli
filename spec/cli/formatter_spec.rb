# frozen_string_literal: true

require 'spec_helper'
require 'cli/formatter'
require 'models/parking_complex'
require 'models/entry_point'
require 'models/small_parking_slot'
require 'models/medium_parking_slot'
require 'models/large_parking_slot'
require 'models/small_vehicle'
require 'models/parking_ticket'

RSpec.describe Formatter do
  let(:formatter) { Formatter.new }

  describe '#format_header' do
    it 'formats a header with decoration' do
      header = formatter.format_header('Test Header')

      expect(header).to include('TEST HEADER')
      expect(header).to match(/={10,}/) # Should include a line of = characters
    end

    it 'respects the specified length' do
      header = formatter.format_header('Test', length: 20)

      expect(header.lines.first.strip.length).to eq(20)
    end
  end

  describe '#format_section' do
    it 'formats a section with a subheader' do
      section = formatter.format_section('Test Section')

      expect(section).to include('Test Section')
      expect(section).to match(/-{10,}/) # Should include a line of - characters
    end
  end

  describe '#format_table' do
    it 'formats an array of hashes as a table' do
      data = [
        { id: 1, name: 'Item 1', status: 'Active' },
        { id: 2, name: 'Item 2', status: 'Inactive' }
      ]

      table = formatter.format_table(data, columns: %i[id name status])

      expect(table).to include('ID')
      expect(table).to include('NAME')
      expect(table).to include('STATUS')
      expect(table).to include('Item 1')
      expect(table).to include('Item 2')
      expect(table).to include('Active')
      expect(table).to include('Inactive')
    end

    it 'aligns columns correctly' do
      data = [
        { id: 1, name: 'Short', status: 'Active' },
        { id: 2, name: 'Much Longer Name', status: 'Inactive' }
      ]

      table = formatter.format_table(data, columns: %i[id name status])

      # The name column width should accommodate the longest entry
      expect(table).to match(/NAME\s{10,}/) # Many spaces after SHORT
    end

    it 'handles empty data' do
      table = formatter.format_table([], columns: %i[id name])

      expect(table).to include('No data to display')
    end

    it 'supports custom column headers' do
      data = [
        { id: 1, name: 'Item 1' }
      ]

      headers = { id: 'ITEM ID', name: 'ITEM NAME' }
      table = formatter.format_table(data, columns: %i[id name], headers: headers)

      expect(table).to include('ITEM ID')
      expect(table).to include('ITEM NAME')
    end
  end

  describe '#format_list' do
    it 'formats an array of strings as a bulleted list' do
      items = ['Item 1', 'Item 2', 'Item 3']

      list = formatter.format_list(items)

      items.each do |item|
        expect(list).to include("* #{item}")
      end
    end

    it 'handles empty lists' do
      list = formatter.format_list([])

      expect(list).to include('No items to display')
    end

    it 'supports custom bullet points' do
      items = ['Item 1', 'Item 2']

      list = formatter.format_list(items, bullet: '>')

      items.each do |item|
        expect(list).to include("> #{item}")
      end
    end
  end

  describe '#format_ticket' do
    let(:entry_time) { Time.new(2023, 6, 10, 10, 0, 0) }
    let(:vehicle) { SmallVehicle.new('SV123') }
    let(:slot) { SmallParkingSlot.new(1, [1, 4, 7]) }
    let(:entry_point) { EntryPoint.new(0) }
    let(:ticket) { ParkingTicket.new(vehicle, slot, entry_point, entry_time) }

    it 'formats an active parking ticket' do
      formatted = formatter.format_ticket(ticket)

      expect(formatted).to include('PARKING TICKET')
      expect(formatted).to include('SV123')
      expect(formatted).to include('ACTIVE')
      expect(formatted).to include(entry_time.to_s)
    end

    it 'formats a completed parking ticket' do
      exit_time = entry_time + (2 * 3600)
      ticket.exit_time = exit_time
      ticket.fee = 40

      formatted = formatter.format_ticket(ticket)

      expect(formatted).to include('PARKING TICKET')
      expect(formatted).to include('SV123')
      expect(formatted).to include('COMPLETED')
      expect(formatted).to include(entry_time.to_s)
      expect(formatted).to include(exit_time.to_s)
      expect(formatted).to include('Fee: 40 pesos')
    end
  end

  describe '#format_status' do
    let(:entry_points) { [EntryPoint.new(0), EntryPoint.new(1), EntryPoint.new(2)] }
    let(:parking_slots) do
      [
        SmallParkingSlot.new(1, [1, 4, 7]),
        MediumParkingSlot.new(2, [2, 3, 8]),
        LargeParkingSlot.new(3, [5, 1, 6])
      ]
    end
    let(:parking_complex) { ParkingComplex.new(entry_points, parking_slots) }

    it 'formats the parking complex status' do
      formatted = formatter.format_status(parking_complex)

      expect(formatted).to include('PARKING COMPLEX STATUS')
      expect(formatted).to include('Entry Points: 3')
      expect(formatted).to include('Parking Slots: 3')
      expect(formatted).to include('Available Slots: 3')
    end

    it 'updates status when vehicles are parked' do
      # Create a vehicle and park it
      vehicle = SmallVehicle.new('SV123')
      parking_complex.park(vehicle, entry_points[0])

      formatted = formatter.format_status(parking_complex)

      expect(formatted).to include('Parked Vehicles: 1')
      expect(formatted).to include('Available Slots: 2')
    end
  end

  describe '#format_status' do
    let(:entry_points) { [EntryPoint.new(0), EntryPoint.new(1), EntryPoint.new(2)] }
    let(:parking_slots) do
      [
        SmallParkingSlot.new(1, [1, 4, 7]),
        MediumParkingSlot.new(2, [2, 3, 8]),
        LargeParkingSlot.new(3, [5, 1, 6])
      ]
    end
    let(:parking_complex) { ParkingComplex.new(entry_points, parking_slots) }

    it 'formats the parking complex status' do
      formatted = formatter.format_status(parking_complex)

      expect(formatted).to include('PARKING COMPLEX STATUS')
      expect(formatted).to include('Entry Points: 3')
      expect(formatted).to include('Parking Slots: 3')
      expect(formatted).to include('Available Slots: 3')
    end

    it 'updates status when vehicles are parked' do
      # Create a vehicle and park it
      vehicle = SmallVehicle.new('SV123')
      parking_complex.park(vehicle, entry_points[0])

      formatted = formatter.format_status(parking_complex)

      expect(formatted).to include('Parked Vehicles: 1')
      expect(formatted).to include('Available Slots: 2')
    end
  end

  describe '#format_slots' do
    let(:slots) do
      [
        SmallParkingSlot.new(1, [1, 4, 7]),
        MediumParkingSlot.new(2, [2, 3, 8]),
        LargeParkingSlot.new(3, [5, 1, 6])
      ]
    end

    it 'formats a list of parking slots as a table' do
      formatted = formatter.format_slots(slots)

      expect(formatted).to include('PARKING SLOTS')
      expect(formatted).to include('ID')
      expect(formatted).to include('TYPE')
      expect(formatted).to include('STATUS')
      slots.each do |slot|
        expect(formatted).to include(slot.id.to_s)
        expect(formatted).to include(slot.size.to_s.upcase)
      end
    end

    it 'shows status correctly' do
      # Mark one slot as occupied
      slots[1].occupy

      formatted = formatter.format_slots(slots)

      expect(formatted).to include('AVAILABLE')
      expect(formatted).to include('OCCUPIED')
    end

    it 'handles empty slot list' do
      formatted = formatter.format_slots([])

      expect(formatted).to include('No parking slots available')
    end

    it 'supports filtering by type' do
      formatted = formatter.format_slots(slots, type: 'small')

      expect(formatted).to include('SMALL PARKING SLOTS')
      expect(formatted).to include(slots[0].id.to_s)
      expect(formatted).not_to include(slots[1].id.to_s) # Medium slot
      expect(formatted).not_to include(slots[2].id.to_s) # Large slot
    end
  end

  describe '#format_vehicles' do
    let(:vehicles) do
      [
        { id: 'SV123', type: 'small', slot_id: 1 },
        { id: 'MV456', type: 'medium', slot_id: 2 },
        { id: 'LV789', type: 'large', slot_id: 3 }
      ]
    end

    it 'formats a list of parked vehicles as a table' do
      formatted = formatter.format_vehicles(vehicles)

      expect(formatted).to include('PARKED VEHICLES')
      expect(formatted).to include('ID')
      expect(formatted).to include('TYPE')
      expect(formatted).to include('SLOT')
      vehicles.each do |vehicle|
        expect(formatted).to include(vehicle[:id])
        expect(formatted).to include(vehicle[:type])
        expect(formatted).to include(vehicle[:slot_id].to_s)
      end
    end

    it 'handles empty vehicle list' do
      formatted = formatter.format_vehicles([])

      expect(formatted).to include('No vehicles currently parked')
    end
  end

  describe '#format_error' do
    it 'formats an error message' do
      error = formatter.format_error('This is an error message')

      expect(error).to include('ERROR')
      expect(error).to include('This is an error message')
    end
  end

  describe '#format_success' do
    it 'formats a success message' do
      success = formatter.format_success('Operation completed successfully')

      expect(success).to include('SUCCESS')
      expect(success).to include('Operation completed successfully')
    end
  end
end
