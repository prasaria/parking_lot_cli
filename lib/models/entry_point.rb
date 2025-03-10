# frozen_string_literal: true

# Represents an entry point to the parking complex
# Entry points are used to calculate distances to parking slots
class EntryPoint
  include Comparable

  attr_reader :id

  # Initialize a new entry point with the given identifier
  # @param id [Integer, String] The entry point identifier (must be non-negative)
  # @raise [ArgumentError] If id is negative or non-numeric
  def initialize(id)
    @id = convert_and_validate_id(id)
  end

  # Compare this entry point with another object
  # @param other [Object] The object to compare with
  # @return [Integer] -1, 0, or 1
  # @raise [ArgumentError] If other is not an EntryPoint
  def <=>(other)
    unless other.is_a?(EntryPoint)
      raise ArgumentError, "Comparison of EntryPoint with #{other.class} failed"
    end

    id <=> other.id
  end

  # Check if this entry point is equal to another object
  # Two entry points are considered equal if they have the same ID
  # @param other [Object] The object to compare with
  # @return [Boolean] true if the entry points are equal, false otherwise
  def ==(other)
    return false unless other.is_a?(EntryPoint)

    id == other.id
  end

  # Alias eql? to == for hash equality
  alias eql? ==

  # Implement hash based on the id for consistent hash behavior
  # @return [Integer] The hash code
  def hash
    id.hash
  end

  # String representation of the entry point
  # @return [String] A string representation
  def to_s
    "EntryPoint ##{id}"
  end

  private

  # Convert and validate the id parameter
  # @param id [Integer, String] The id to validate
  # @return [Integer] The validated id
  # @raise [ArgumentError] If id is negative or non-numeric
  def convert_and_validate_id(id)
    begin
      numeric_id = Integer(id)
    rescue ArgumentError, TypeError
      raise ArgumentError, "Entry point ID must be numeric, got: #{id.inspect}"
    end

    if numeric_id.negative?
      raise ArgumentError, "Entry point ID must be non-negative, got: #{numeric_id}"
    end

    numeric_id
  end
end
