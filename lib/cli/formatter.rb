# frozen_string_literal: true

# Class responsible for formatting output for the CLI interface
class Formatter # rubocop:disable Metrics/ClassLength
  DEFAULT_WIDTH = 80

  # Format a header with decoration
  # @param text [String] The header text
  # @param length [Integer] The desired length of the header line
  # @return [String] The formatted header
  def format_header(text, length: DEFAULT_WIDTH)
    header = text.upcase
    line = '=' * length

    "#{line}\n#{header}\n#{line}\n"
  end

  # Format a section with a subheader
  # @param text [String] The section text
  # @param length [Integer] The desired length of the section line
  # @return [String] The formatted section
  def format_section(text, length: DEFAULT_WIDTH)
    header = text
    line = '-' * length

    "#{header}\n#{line}\n"
  end

  # Format data as a table
  # @param data [Array<Hash>] The data to format
  # @param columns [Array<Symbol>] The columns to include
  # @param headers [Hash] Custom column headers (defaults to uppercase column names)
  # @return [String] The formatted table
  def format_table(data, columns:, headers: nil) # rubocop:disable Metrics/MethodLength
    return "No data to display\n" if data.empty?

    # Initialize headers if not provided
    headers ||= {}

    # Calculate column widths
    widths = calculate_column_widths(data, columns, headers)

    # Format header row
    table = format_table_header(columns, headers, widths)

    # Format data rows
    data.each do |row|
      line = columns.map do |col|
        value = row[col].to_s
        pad_value(value, widths[col])
      end.join(' | ')

      table += "| #{line} |\n"
    end

    table += format_table_footer(widths)
    table
  end

  # Format a list of items
  # @param items [Array<String>] The items to format
  # @param bullet [String] The bullet point to use
  # @return [String] The formatted list
  def format_list(items, bullet: '*')
    return "No items to display\n" if items.empty?

    "#{items.map { |item| "#{bullet} #{item}" }.join("\n")}\n"
  end

  # Format a parking ticket
  # @param ticket [ParkingTicket] The ticket to format
  # @return [String] The formatted ticket
  def format_ticket(ticket) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
    status = ticket.active? ? 'ACTIVE' : 'COMPLETED'

    output = format_header('Parking Ticket', length: 50)
    output += "Status: #{status}\n\n"
    output += "Vehicle ID: #{ticket.vehicle.id}\n"
    output += "Vehicle Type: #{ticket.vehicle.size.to_s.upcase}\n"
    output += "Slot ID: #{ticket.slot.id}\n"
    output += "Slot Type: #{ticket.slot.size.to_s.upcase}\n"
    output += "Entry Point: #{ticket.entry_point.id}\n"
    output += "Entry Time: #{ticket.entry_time}\n"

    unless ticket.active?
      output += "Exit Time: #{ticket.exit_time}\n"
      output += "Duration: #{ticket.duration_in_hours} hours\n"
      output += "Fee: #{ticket.fee} pesos\n"
    end

    output += "\nNote: Continuous rate applied from previous parking session\n" if ticket.previous_ticket

    output
  end

  # Format parking complex status
  # @param parking_complex [ParkingComplex] The parking complex
  # @return [String] The formatted status
  def format_status(parking_complex)
    output = format_header('Parking Complex Status')

    # General statistics
    output += "\nEntry Points: #{parking_complex.entry_points.size}\n"
    output += "Parking Slots: #{parking_complex.parking_slots.size}\n"
    output += "Parked Vehicles: #{parking_complex.parked_vehicles_count}\n"
    output += "Available Slots: #{parking_complex.available_parking_slots.size}\n"

    # Slots by type
    output += "\nAvailable Slots by Type:\n"
    output += "Small: #{parking_complex.available_parking_slots(type: :small).size}\n"
    output += "Medium: #{parking_complex.available_parking_slots(type: :medium).size}\n"
    output += "Large: #{parking_complex.available_parking_slots(type: :large).size}\n"

    output
  end

  # Format parking slots
  # @param slots [Array<ParkingSlot>] The slots to format
  # @param type [String, nil] The type of slots to filter by
  # @return [String] The formatted slots
  def format_slots(slots, type: nil) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
    return "No parking slots available\n" if slots.empty?

    # Filter by type if specified
    if type
      type_sym = type.to_sym
      slots = slots.select { |slot| slot.size == type_sym }
      title = "#{type.capitalize} Parking Slots"
    else
      title = 'Parking Slots'
    end

    output = format_header(title)

    # Convert slots to table data
    data = slots.map do |slot|
      status = slot.available? ? 'AVAILABLE' : 'OCCUPIED'
      {
        id: slot.id,
        type: slot.size.to_s.upcase,
        status: status
      }
    end

    # Sort by ID
    data.sort_by! { |row| row[:id] }

    # Format as table
    output += format_table(data, columns: %i[id type status])

    output
  end

  # Format parked vehicles
  # @param vehicles [Array<Hash>] The vehicles to format
  # @return [String] The formatted vehicles
  def format_vehicles(vehicles)
    return "No vehicles currently parked\n" if vehicles.empty?

    output = format_header('Parked Vehicles')

    # Format as table
    output += format_table(vehicles, columns: %i[id type slot_id],
                                     headers: { id: 'ID', type: 'TYPE', slot_id: 'SLOT' })

    output
  end

  # Format an error message
  # @param message [String] The error message
  # @return [String] The formatted error message
  def format_error(message)
    "\nERROR: #{message}\n"
  end

  # Format a success message
  # @param message [String] The success message
  # @return [String] The formatted success message
  def format_success(message)
    "\nSUCCESS: #{message}\n"
  end

  private

  # Calculate column widths for a table
  # @param data [Array<Hash>] The data
  # @param columns [Array<Symbol>] The columns
  # @param headers [Hash] Custom headers
  # @return [Hash] Map of column to width
  def calculate_column_widths(data, columns, headers)
    widths = {}

    columns.each do |col|
      # Get header length
      header = headers[col] || col.to_s.upcase
      header_length = header.length

      # Find maximum value length
      value_length = data.map { |row| row[col].to_s.length }.max || 0

      # Use the larger of header or value length, plus padding
      widths[col] = [header_length, value_length].max + 2
    end

    widths
  end

  # Format the header row of a table
  # @param columns [Array<Symbol>] The columns
  # @param headers [Hash] Custom headers
  # @param widths [Hash] Column widths
  # @return [String] The formatted header row
  def format_table_header(columns, headers, widths) # rubocop:disable Metrics/AbcSize
    # Format header row
    header = columns.map do |col|
      header_text = headers[col] || col.to_s.upcase
      pad_value(header_text, widths[col])
    end.join(' | ')

    # Calculate total line width
    line_width = columns.sum { |col| widths[col] } + (columns.size * 3) - 1

    table = "+#{'-' * line_width}+\n"
    table += "| #{header} |\n"
    table += "+#{'-' * line_width}+\n"

    table
  end

  # Format the footer row of a table
  # @param widths [Hash] Column widths
  # @return [String] The formatted footer row
  def format_table_footer(widths)
    line_width = widths.values.sum + (widths.size * 3) - 1
    "+#{'-' * line_width}+\n"
  end

  # Pad a value to a specified width
  # @param value [String] The value to pad
  # @param width [Integer] The desired width
  # @return [String] The padded value
  def pad_value(value, width)
    value.to_s.ljust(width)
  end
end
