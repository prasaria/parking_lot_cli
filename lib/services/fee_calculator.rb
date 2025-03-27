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

  # Maximum gap in hours for continuous rate to apply
  CONTINUOUS_RATE_MAX_GAP = 1

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

  # Calculate the fee with continuous rate for one or more tickets
  # @param tickets_args [ParkingTicket, Array<ParkingTicket>] The tickets to calculate the fee for
  # @return [Integer] The calculated fee in pesos
  # @raise [ArgumentError] If tickets is nil or empty
  def calculate_fee_with_continuous_rate(*tickets_args)
    # Handle both arrays and individual tickets
    tickets = if tickets_args.size == 1 && tickets_args.first.is_a?(Array)
                tickets_args.first
              else
                tickets_args
              end

    validate_tickets(tickets)

    # If only one ticket, just use regular fee calculation
    return calculate_fee(tickets.first) if tickets.size == 1

    # Sort tickets by entry time
    sorted_tickets = tickets.sort_by(&:entry_time)

    # Check if continuous rate applies
    segments = split_into_continuous_segments(sorted_tickets)

    # Calculate fee for each segment and sum
    segments.sum { |segment| calculate_segment_fee(segment) }
  end

  private

  # Validate a single ticket
  # @param ticket [ParkingTicket] The ticket to validate
  # @raise [ArgumentError] If ticket is nil or still active
  def validate_ticket(ticket)
    if ticket.nil?
      raise ArgumentError, 'Ticket cannot be nil'
    elsif ticket.active?
      raise ArgumentError, 'Cannot calculate fee for active ticket'
    end
  end

  # Validate an array of tickets
  # @param tickets [Array<ParkingTicket>] The tickets to validate
  # @raise [ArgumentError] If tickets is nil or empty, or any ticket is active
  def validate_tickets(tickets)
    raise ArgumentError, 'Tickets cannot be nil or empty' if tickets.nil? || tickets.empty?

    tickets.each { |ticket| validate_ticket(ticket) }
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

  # Split tickets into continuous segments based on return time
  # @param tickets [Array<ParkingTicket>] The sorted tickets
  # @return [Array<Array<ParkingTicket>>] Array of ticket segments
  def split_into_continuous_segments(tickets) # rubocop:disable Metrics/MethodLength
    segments = [[tickets.first]]

    tickets[1..].each_with_index do |ticket, index|
      prev_ticket = tickets[index]
      time_gap = (ticket.entry_time - prev_ticket.exit_time) / 3600.0 # in hours

      if time_gap <= CONTINUOUS_RATE_MAX_GAP
        # Add to current segment if within continuous rate window
        segments.last << ticket
      else
        # Start a new segment
        segments << [ticket]
      end
    end

    segments
  end

  # Calculate fee for a continuous segment of tickets
  # @param segment [Array<ParkingTicket>] The segment of tickets
  # @return [Integer] The calculated fee
  def calculate_segment_fee(segment)
    # Calculate total actual parking duration (excluding gaps)
    total_parking_hours = calculate_total_parking_hours(segment)

    # Get the last ticket in the segment
    last_ticket = segment.last

    # Calculate days and remainder hours based on actual parking time
    days, remainder_hours = total_parking_hours.divmod(HOURS_PER_DAY)

    # If there are complete days, apply the daily rate
    daily_fee = days * DAILY_RATE

    # Calculate fee for remainder hours using the latest slot
    remainder_fee = if days.positive?
                      calculate_remainder_fee(remainder_hours, last_ticket.slot)
                    else
                      calculate_hourly_fee(total_parking_hours, last_ticket.slot)
                    end

    daily_fee + remainder_fee
  end

  # Calculate total parking hours for a segment (excluding gaps)
  # @param segment [Array<ParkingTicket>] The segment of tickets
  # @return [Integer] Total parking hours, rounded up
  def calculate_total_parking_hours(segment)
    # Sum the actual parking duration for each ticket
    total_duration = segment.sum do |ticket|
      (ticket.exit_time - ticket.entry_time) / 3600.0
    end

    # Round up to the nearest hour
    total_duration.ceil
  end
end
