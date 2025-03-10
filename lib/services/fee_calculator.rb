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

  # Calculate the parking fee for a ticket
  # @param ticket [ParkingTicket] The parking ticket to calculate the fee for
  # @return [Integer] The calculated fee in pesos
  # @raise [ArgumentError] If ticket is nil or still active
  def calculate_fee(ticket)
    validate_ticket(ticket)

    # For now, just implement the base rate calculation
    # Duration is already rounded up to the nearest hour in the ticket
    duration_hours = ticket.duration_in_hours

    # If duration is less than or equal to the base rate hours, return the base rate
    return BASE_RATE if duration_hours <= BASE_RATE_HOURS

    # Future implementation will handle hourly and daily rates
    BASE_RATE
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
end
