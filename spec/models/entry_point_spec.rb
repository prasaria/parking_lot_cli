# frozen_string_literal: true

require 'spec_helper'
require 'models/entry_point'

RSpec.describe EntryPoint do
  let(:entry_point_id) { 0 }
  let(:entry_point) { EntryPoint.new(entry_point_id) }

  describe '.new' do
    it 'creates a new entry point with the given id' do
      expect(entry_point.id).to eq(entry_point_id)
    end

    it 'accepts a string id and converts it to integer' do
      string_id_entry_point = EntryPoint.new('1')
      expect(string_id_entry_point.id).to eq(1)
    end

    it 'raises an error for a negative id' do
      expect { EntryPoint.new(-1) }.to raise_error(ArgumentError)
    end

    it 'raises an error for a non-numeric id' do
      expect { EntryPoint.new('abc') }.to raise_error(ArgumentError)
    end
  end

  describe 'attributes' do
    it 'has a readable id' do
      expect(entry_point.id).to eq(entry_point_id)
    end

    it 'does not allow id to be changed' do
      expect { entry_point.id = 1 }.to raise_error(NoMethodError)
    end
  end

  describe 'equality' do
    it 'considers two entry points with the same id to be equal' do
      entry_point1 = EntryPoint.new(1)
      entry_point2 = EntryPoint.new(1)

      expect(entry_point1).to eq(entry_point2)
    end

    it 'considers two entry points with different ids to be different' do
      entry_point1 = EntryPoint.new(0)
      entry_point2 = EntryPoint.new(1)

      expect(entry_point1).not_to eq(entry_point2)
    end

    it 'considers entry points and other objects to be different' do
      expect(entry_point).not_to eq('not an entry point')
    end
  end

  describe 'hash and eql?' do
    it 'has consistent hash and eql? behavior' do
      entry_point1 = EntryPoint.new(1)
      entry_point2 = EntryPoint.new(1)

      # Two equal objects should have the same hash
      expect(entry_point1.hash).to eq(entry_point2.hash)

      # Hash collections should treat them as equal
      hash = { entry_point1 => 'value' }
      expect(hash[entry_point2]).to eq('value')
    end
  end

  describe 'comparable' do
    it 'is comparable based on id' do
      entry_point0 = EntryPoint.new(0)
      entry_point1 = EntryPoint.new(1)
      entry_point2 = EntryPoint.new(2)

      expect(entry_point0).to be < entry_point1
      expect(entry_point1).to be < entry_point2
      expect(entry_point2).to be > entry_point0

      entry_points = [entry_point2, entry_point0, entry_point1]
      expect(entry_points.sort).to eq([entry_point0, entry_point1, entry_point2])
    end

    it 'raises an error when comparing with non-entry point objects' do
      expect { entry_point < 'not an entry point' }.to raise_error(ArgumentError)
    end
  end

  describe 'string representation' do
    it 'has a meaningful string representation' do
      expect(entry_point.to_s).to eq("EntryPoint ##{entry_point_id}")
    end
  end
end
