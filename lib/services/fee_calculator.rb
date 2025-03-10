# frozen_string_literal: true

# Service responsible for calculating parking fees based on various rules
# - Flat rate of 40 pesos for the first 3 hours
# - Hourly rates beyond 3 hours based on slot size:
#   * Small slot (SP): 20 pesos/hour
#   * Medium slot (MP): 60 pesos/hour
#   * Large slot (LP): 100 pesos/hour
# - Flat rate of 5000 pesos per 24-hour chunk for long-term parking
# - Continuous rate for vehicles returning within 1 hour of exit
class FeeCalculator # rubocop:disable Metrics/ClassLength
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
  # @param tickets [ParkingTicket, Array<ParkingTicket>] The tickets to calculate the fee for
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
    # Create a timeline of slot changes with durations
    timeline = create_timeline(segment)

    # Calculate total duration (including gaps)
    total_hours = calculate_total_hours(timeline)

    # Calculate days and remainder hours
    days, remainder_hours = total_hours.divmod(HOURS_PER_DAY)

    # If there are complete days, apply the daily rate
    daily_fee = days * DAILY_RATE

    # Calculate fee for remainder hours with mixed slot types
    remainder_fee = if days.positive?
                      calculate_remainder_fee(remainder_hours, segment.last.slot)
                    else
                      calculate_mixed_slot_fee(timeline, total_hours)
                    end

    daily_fee + remainder_fee
  end

  # Create a timeline of slot changes with durations
  # @param segment [Array<ParkingTicket>] The segment of tickets
  # @return [Array<Hash>] Array of duration and slot pairs
  def create_timeline(segment) # rubocop:disable Metrics/AbcSize
    timeline = []

    segment.each_with_index do |ticket, index|
      # Add actual parking duration
      actual_duration = (ticket.exit_time - ticket.entry_time) / 3600.0
      timeline << { duration: actual_duration, slot: ticket.slot }

      # Add gap to next ticket if not the last ticket
      next unless index < segment.size - 1

      next_ticket = segment[index + 1]
      gap_duration = (next_ticket.entry_time - ticket.exit_time) / 3600.0
      timeline << { duration: gap_duration, slot: nil } if gap_duration.positive?
    end

    timeline
  end

  # Calculate total hours from a timeline
  # @param timeline [Array<Hash>] The timeline
  # @return [Integer] Total hours, rounded up
  def calculate_total_hours(timeline)
    total_duration = timeline.sum { |item| item[:duration] }
    total_duration.ceil
  end

  # Calculate fee for a mixed set of slot types for a duration
  # @param timeline [Array<Hash>] The timeline of slot changes
  # @param total_hours [Integer] Total duration in hours
  # @return [Integer] The calculated fee
  def calculate_mixed_slot_fee(timeline, total_hours)
    # If total hours is within base rate, just return base rate
    return BASE_RATE if total_hours <= BASE_RATE_HOURS

    # For durations exceeding base rate, we need to calculate mixed rates
    excess_hours = total_hours - BASE_RATE_HOURS

    # Create a prioritized list of slot hours (larger slots take precedence)
    slot_hours = calculate_slot_hours(timeline)

    # Calculate the excess fee based on prioritized slot hours
    excess_fee = calculate_excess_fee(slot_hours, excess_hours)

    # Return base rate plus excess fee
    BASE_RATE + excess_fee
  end

  # Calculate hours per slot type from a timeline
  # @param timeline [Array<Hash>] The timeline
  # @return [Hash] Hours per slot size
  def calculate_slot_hours(timeline)
    # Initial slot hours hash
    slot_hours = { small: 0, medium: 0, large: 0 }

    # Sum up hours by slot type
    timeline.each do |item|
      next if item[:slot].nil?

      slot_hours[item[:slot].size] += item[:duration]
    end

    slot_hours
  end

  # Calculate excess fee based on prioritized slot hours
  # @param slot_hours [Hash] Hours per slot size
  # @param excess_hours [Integer] Excess hours beyond base rate
  # @return [Integer] The excess fee
  def calculate_excess_fee(slot_hours, excess_hours)
    remaining_hours = excess_hours
    total_fee = 0

    # Process slots in order of highest to lowest rate
    %i[large medium small].each do |size|
      hours = [slot_hours[size].ceil, remaining_hours].min
      total_fee += hours * HOURLY_RATES[size]
      remaining_hours -= hours
      break if remaining_hours <= 0
    end

    total_fee
  end
end
