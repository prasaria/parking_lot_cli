# frozen_string_literal: true

require 'spec_helper'
require 'cli/menu'
require 'cli/command_handler'
require 'cli/formatter'
require 'models/parking_complex'
require 'models/entry_point'
require 'models/small_parking_slot'
require 'models/medium_parking_slot'
require 'models/large_parking_slot'

RSpec.describe Menu do
  # Helpers for input/output testing
  let(:input) { StringIO.new }
  let(:output) { StringIO.new }

  # Parking complex setup
  let(:entry_points) { [EntryPoint.new(0), EntryPoint.new(1), EntryPoint.new(2)] }
  let(:parking_slots) do
    [
      SmallParkingSlot.new(1, [1, 4, 7]),
      MediumParkingSlot.new(2, [2, 3, 8]),
      LargeParkingSlot.new(3, [5, 1, 6])
    ]
  end
  let(:parking_complex) { ParkingComplex.new(entry_points, parking_slots) }

  # Menu and dependencies
  let(:command_handler) { CommandHandler.new(parking_complex) }
  let(:formatter) { Formatter.new }
  let(:menu) { Menu.new(command_handler, formatter, input: input, output: output) }

  describe '#initialize' do
    it 'creates a menu with the given command handler and formatter' do
      expect(menu.command_handler).to eq(command_handler)
      expect(menu.formatter).to eq(formatter)
    end

    it 'uses the provided input and output streams' do
      expect(menu.instance_variable_get(:@input)).to eq(input)
      expect(menu.instance_variable_get(:@output)).to eq(output)
    end

    it 'defaults to STDIN and STDOUT if no streams provided' do
      default_menu = Menu.new(command_handler, formatter)

      expect(default_menu.instance_variable_get(:@input)).to eq($stdin)
      expect(default_menu.instance_variable_get(:@output)).to eq($stdout)
    end

    it 'initializes with running state true' do
      expect(menu.running?).to be true
    end
  end

  describe '#display_welcome' do
    it 'displays a welcome message' do
      menu.display_welcome

      expect(output.string).to include('PARKING SYSTEM')
      expect(output.string).to include('Welcome')
    end

    it 'displays initial parking complex status' do
      menu.display_welcome

      expect(output.string).to include('PARKING COMPLEX STATUS')
      expect(output.string).to include('Entry Points: 3')
      expect(output.string).to include('Parking Slots: 3')
    end
  end

  describe '#display_prompt' do
    it 'displays a command prompt' do
      menu.display_prompt

      expect(output.string).to include('Enter command')
    end
  end

  describe '#stop' do
    it 'sets running state to false' do
      menu.stop

      expect(menu.running?).to be false
    end
  end

  describe '#clear_screen' do
    it 'outputs screen clear sequence' do
      menu.clear_screen

      # Check for ANSI clear screen sequence or simple newlines
      expect(output.string).to match(/(\e\[2J|\e\[H|\n{2,})/)
    end
  end

  describe '#running?' do
    it 'returns current running state' do
      expect(menu.running?).to be true

      menu.stop

      expect(menu.running?).to be false
    end
  end

  describe 'menu navigation' do
    # Helper method to simulate user input
    def provide_input(text)
      input.puts(text)
      input.rewind
    end

    describe '#start' do
      before do
        # Prevent infinite loop by making menu stop after processing one command
        allow(menu).to receive(:running?).and_return(true, false)
      end

      it 'displays welcome message and prompt' do
        provide_input('exit')
        menu.start

        expect(output.string).to include('PARKING SYSTEM')
        expect(output.string).to include('Enter command')
      end

      it 'processes user commands' do
        provide_input('status')
        menu.start

        expect(output.string).to include('Parking Complex Status')
        expect(output.string).to include('Entry Points: 3')
      end

      it 'handles the exit command' do
        provide_input('exit')

        expect { menu.start }.to change { menu.running? }.from(true).to(false)
        expect(output.string).to include('Goodbye')
      end

      it 'displays success messages' do
        provide_input('help')
        menu.start

        expect(output.string).to include('Available commands')
      end

      it 'displays error messages for invalid commands' do
        provide_input('invalid_command')
        menu.start

        expect(output.string).to include('ERROR')
        expect(output.string).to include('Unknown command')
      end
    end

    describe 'command processing' do
      before do
        # Prevent infinite loop by making menu stop after processing one command
        allow(menu).to receive(:running?).and_return(true, false)
      end

      context 'help command' do
        it 'displays available commands' do
          provide_input('help')
          menu.start

          expect(output.string).to include('Available commands')
          expect(output.string).to include('help')
          expect(output.string).to include('status')
          expect(output.string).to include('park')
          expect(output.string).to include('unpark')
        end
      end

      context 'status command' do
        it 'displays parking complex status' do
          provide_input('status')
          menu.start

          expect(output.string).to include('Parking Complex Status')
          expect(output.string).to include('Entry Points: 3')
          expect(output.string).to include('Parking Slots: 3')
        end
      end

      context 'park command' do
        it 'processes a valid park command' do
          provide_input('park SV123 small 0')
          menu.start

          expect(output.string).to include('Vehicle SV123 parked successfully')
        end

        it 'handles invalid park command' do
          provide_input('park')
          menu.start

          expect(output.string).to include('ERROR')
          expect(output.string).to include('Invalid command format')
        end
      end

      context 'unpark command' do
        before do
          # Park a vehicle first
          command_handler.execute_command('park SV123 small 0')
        end

        it 'processes a valid unpark command' do
          provide_input('unpark SV123')
          menu.start

          expect(output.string).to include('Vehicle SV123 unparked successfully')
        end

        it 'handles non-existent vehicle' do
          provide_input('unpark NOTFOUND')
          menu.start

          expect(output.string).to include('ERROR')
          expect(output.string).to include('not parked')
        end
      end

      context 'slots command' do
        it 'displays all parking slots' do
          provide_input('slots')
          menu.start

          expect(output.string).to include('Parking Slots')
          expect(output.string).to include('ID')
          expect(output.string).to include('Type')
          expect(output.string).to include('Status')
        end

        it 'displays slots filtered by type' do
          provide_input('slots small')
          menu.start

          expect(output.string).to include('Small Parking Slots')
          expect(output.string).to include('ID: 1')
          expect(output.string).not_to include('ID: 2') # Medium slot
        end
      end

      context 'vehicles command' do
        before do
          # Park a vehicle first
          command_handler.execute_command('park SV123 small 0')
        end

        it 'displays parked vehicles' do
          provide_input('vehicles')
          menu.start

          expect(output.string).to include('Parked Vehicles')
          expect(output.string).to include('SV123')
        end
      end

      context 'with multiple commands' do
        it 'processes commands in sequence until exit' do
          # Allow menu to run for 3 commands before stopping
          allow(menu).to receive(:running?).and_return(true, true, true, false)

          # Simulate multiple inputs
          input.puts('help')
          input.puts('status')
          input.puts('exit')
          input.rewind

          menu.start

          expect(output.string).to include('Available commands')
          expect(output.string).to include('Parking Complex Status')
          expect(output.string).to include('Goodbye')
        end
      end
    end

    describe 'handling edge cases' do
      it 'handles nil input gracefully' do
        # Simulate EOF (Ctrl+D)
        allow(input).to receive(:gets).and_return(nil)

        menu.start

        expect(output.string).to include('Goodbye')
      end

      it 'handles input with extra whitespace' do
        provide_input('  help  ')
        allow(menu).to receive(:running?).and_return(true, false)

        menu.start

        expect(output.string).to include('Available commands')
      end

      it 'handles empty input' do
        provide_input('')
        allow(menu).to receive(:running?).and_return(true, false)

        menu.start

        expect(output.string).to include('ERROR')
        expect(output.string).to include('Invalid command')
      end
    end
  end
end
