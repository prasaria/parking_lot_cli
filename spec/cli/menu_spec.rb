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
end
