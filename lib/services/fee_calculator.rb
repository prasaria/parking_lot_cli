# frozen_string_literal: true

# Service responsible for calculating parking fees based on various rules
# - Flat rate of 40 pesos for the first 3 hours
# - Hourly rates beyond 3 hours based on slot size:
#   * Small slot (SP): 20 pesos/hour
#   * Medium slot (MP): 60 pesos/hour
#   * Large slot (LP): 100 pesos/hour
# - Flat rate of 5000 pesos per 24-hour chunk for long-term parking
# - Continuous rate for vehicles returning within 1 hour of exit
class FeeCalculator
  # Base flat rate for the first 3 hours (all slot types)
  BASE_RATE = 40

  # Hourly rates after the first 3 hours (by slot size)
  HOURLY_RATES = {
    small: 20,
    medium: 60,
    large: 100
  }.freeze

  # 24-hour flat rate for long-term parking
  DAILY_RATE = 5000

  # Maximum hours covered by the base rate
  BASE_RATE_HOURS = 3

  # Hours in a day for calculating daily rates
  HOURS_PER_DAY = 24

  # Calculate the parking fee for a ticket
  # @param ticket [ParkingTicket] The parking ticket to calculate the fee for
  # @return [Integer] The calculated fee in pesos
  # @raise [ArgumentError] If ticket is nil or still active
  def calculate_fee(ticket)
    validate_ticket(ticket)

    # Get duration in hours (already rounded up)
    duration_hours = ticket.duration_in_hours

    # Calculate days and remainder hours
    days, remainder_hours = duration_hours.divmod(HOURS_PER_DAY)

    # If there are complete days, apply the daily rate
    if days.positive?
      daily_fee = days * DAILY_RATE
      # Add fees for any remainder hours
      remainder_fee = calculate_remainder_fee(remainder_hours, ticket.slot)
      return daily_fee + remainder_fee
    end

    # Otherwise, just calculate based on hourly rates
    calculate_hourly_fee(duration_hours, ticket.slot)
  end

  private

  # Validate the ticket
  # @param ticket [ParkingTicket] The ticket to validate
  # @raise [ArgumentError] If ticket is nil or still active
  def validate_ticket(ticket)
    if ticket.nil?
      raise ArgumentError, 'Ticket cannot be nil'
    elsif ticket.active?
      raise ArgumentError, 'Cannot calculate fee for active ticket'
    end
  end

  # Calculate fee for hours that don't constitute a full day
  # @param hours [Integer] Number of hours
  # @param slot [ParkingSlot] The parking slot
  # @return [Integer] The fee for the given hours
  def calculate_hourly_fee(hours, slot)
    # If duration is less than or equal to the base rate hours, return the base rate
    return BASE_RATE if hours <= BASE_RATE_HOURS

    # For durations exceeding the base rate hours, calculate additional hourly charges
    excess_hours = hours - BASE_RATE_HOURS
    hourly_rate = get_hourly_rate(slot)

    # Calculate and return total fee
    BASE_RATE + (excess_hours * hourly_rate)
  end

  # Calculate fee for remainder hours after complete days
  # @param remainder_hours [Integer] Number of remainder hours
  # @param slot [ParkingSlot] The parking slot
  # @return [Integer] The fee for the remainder hours
  def calculate_remainder_fee(remainder_hours, slot)
    # If there are no remainder hours, return 0
    return 0 if remainder_hours.zero?

    # Otherwise, calculate fee based on the remainder hours
    calculate_hourly_fee(remainder_hours, slot)
  end

  # Get the hourly rate based on the slot size
  # @param slot [ParkingSlot] The parking slot
  # @return [Integer] The hourly rate in pesos
  def get_hourly_rate(slot)
    HOURLY_RATES[slot.size]
  end
end
