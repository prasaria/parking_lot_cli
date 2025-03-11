# frozen_string_literal: true

require 'spec_helper'
require_relative '../main'

RSpec.describe 'Parking System Execution Flow' do
  # Mock standard input/output for testing
  let(:input) { StringIO.new }
  let(:output) { StringIO.new }

  # Create a test instance of the program with mocked IO
  let(:program) { ParkingSystem.new(input: input, output: output) }

  # Helper method to simulate user input
  def provide_input(text)
    input.puts(text)
    input.rewind
  end

  describe 'complete execution scenarios' do
    before do
      # Prevent infinite loop by making menu stop after processing the commands
      allow(program.menu).to receive(:running?).and_return(true, true, true, false)
    end

    it 'executes a complete parking flow: status -> park -> status -> unpark -> status' do
      # Allow enough iterations for all commands
      allow(program.menu).to receive(:running?).and_return(*Array.new(5, true), false)

      # Simulate user input
      input.puts('status')
      input.puts('park SV001 small 0')
      input.puts('status')
      input.puts('unpark SV001')
      input.puts('exit')
      input.rewind

      # Run the program
      program.start

      # Verify the output
      output_text = output.string

      # Check that the welcome message was displayed
      expect(output_text).to include('PARKING SYSTEM')
      expect(output_text).to include('Welcome')

      # Check that status shows correct values before parking
      expect(output_text).to include('Parked Vehicles: 0')

      # Check that parking was successful
      expect(output_text).to include('Vehicle SV001 parked successfully')

      # Check that status shows updated values after parking
      expect(output_text).to include('Parked Vehicles: 1')

      # Check that unparking was successful
      expect(output_text).to include('Vehicle SV001 unparked successfully')
      expect(output_text).to include('Fee:')

      # Check that exit works correctly
      expect(output_text).to include('Goodbye')
    end

    it 'handles invalid commands gracefully' do
      # Simulate user input
      input.puts('invalid_command')
      input.puts('exit')
      input.rewind

      # Run the program
      program.start

      # Verify the output
      output_text = output.string

      # Check that the error was handled gracefully
      expect(output_text).to include('ERROR')
      expect(output_text).to include('Unknown command')

      # Check that the program continued and exited gracefully
      expect(output_text).to include('Goodbye')
    end

    it 'handles complex parking scenarios with multiple vehicles' do
      # Allow enough iterations for all commands
      allow(program.menu).to receive(:running?).and_return(*Array.new(9, true), false)

      # Simulate user input
      input.puts('park SV001 small 0')
      input.puts('park MV001 medium 1')
      input.puts('park LV001 large 2')
      input.puts('vehicles')
      input.puts('slots')
      input.puts('unpark SV001')
      input.puts('unpark MV001')
      input.puts('unpark LV001')
      input.puts('exit')
      input.rewind

      # Run the program
      program.start

      # Verify the output
      output_text = output.string

      # Check that all vehicles were parked successfully
      expect(output_text).to include('Vehicle SV001 parked successfully')
      expect(output_text).to include('Vehicle MV001 parked successfully')
      expect(output_text).to include('Vehicle LV001 parked successfully')

      # Check that vehicles command shows all parked vehicles
      expect(output_text).to include('Parked Vehicles')
      expect(output_text).to include('SV001')
      expect(output_text).to include('MV001')
      expect(output_text).to include('LV001')

      # Check that slots command shows slot status
      expect(output_text).to include('Parking Slots')
      expect(output_text).to include('Occupied')

      # Check that all vehicles were unparked successfully
      expect(output_text).to include('Vehicle SV001 unparked successfully')
      expect(output_text).to include('Vehicle MV001 unparked successfully')
      expect(output_text).to include('Vehicle LV001 unparked successfully')
    end
  end

  describe 'error handling' do
    before do
      # Prevent infinite loop by making menu stop after processing the commands
      allow(program.menu).to receive(:running?).and_return(true, false)
    end

    it 'handles parking when no slots are available' do
      # First, park vehicles in all 6 slots
      6.times do |i|
        program.parking_complex.park(
          SmallVehicle.new("SV00#{i}"),
          program.parking_complex.entry_points[0]
        )
      end

      # Simulate trying to park another vehicle
      input.puts('park SV007 small 0')
      input.rewind

      # Run the program
      program.start

      # Verify the output
      output_text = output.string

      # Check that the error was handled gracefully
      expect(output_text).to include('No available slot')
    end

    it 'handles unparking a vehicle that is not parked' do
      # Simulate trying to unpark a non-existent vehicle
      input.puts('unpark NOTFOUND')
      input.rewind

      # Run the program
      program.start

      # Verify the output
      output_text = output.string

      # Check that the error was handled gracefully
      expect(output_text).to include('ERROR')
      expect(output_text).to include('not parked')
    end
  end

  describe 'system startup and shutdown' do
    it 'initializes all components correctly on startup' do
      # Allow menu.start to return immediately
      allow(program.menu).to receive(:start)

      # Start the program
      program.start

      # Verify that all components were initialized
      expect(program.parking_complex).not_to be_nil
      expect(program.command_handler).not_to be_nil
      expect(program.formatter).not_to be_nil
      expect(program.menu).not_to be_nil

      # Verify that menu.start was called
      expect(program.menu).to have_received(:start)
    end

    it 'shuts down gracefully with exit command' do
      # Simulate exit command
      input.puts('exit')
      input.rewind

      # Run the program
      program.start

      # Verify the output
      output_text = output.string

      # Check that the program exited gracefully
      expect(output_text).to include('Goodbye')
    end
  end
end
