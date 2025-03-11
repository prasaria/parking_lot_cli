# frozen_string_literal: true

# Main CLI menu for the parking system
# Handles user interaction and command processing
class Menu
  attr_reader :command_handler, :formatter

  # Initialize the menu
  # @param command_handler [CommandHandler] Handler for processing commands
  # @param formatter [Formatter] Formatter for output
  # @param input [IO] Input stream (defaults to STDIN)
  # @param output [IO] Output stream (defaults to STDOUT)
  def initialize(command_handler, formatter, input: $stdin, output: $stdout)
    @command_handler = command_handler
    @formatter = formatter
    @input = input
    @output = output
    @running = true
  end

  # Display welcome message and initial status
  def display_welcome
    clear_screen

    welcome_message = <<~WELCOME
      #{formatter.format_header('Parking System')}

      Welcome to the Object-Oriented Mall Parking System!
      Type 'help' for a list of available commands.

      #{formatter.format_status(@command_handler.instance_variable_get(:@parking_complex))}
    WELCOME

    @output.puts(welcome_message)
  end

  # Display command prompt
  def display_prompt
    @output.print("\nEnter command (or 'exit' to quit): ")
  end

  # Stop the menu loop
  def stop
    @running = false
  end

  # Check if the menu is running
  # @return [Boolean] true if the menu is running, false otherwise
  def running?
    @running
  end

  # Clear the screen
  def clear_screen
    # Use ANSI escape sequence to clear screen on most terminals
    # Fall back to newlines if not supported
    @output.print("\e[H\e[2J")
  rescue StandardError
    @output.puts("\n\n")
  end

  # Start the menu loop
  def start
    display_welcome

    while running?
      display_prompt
      command = read_command

      # Break out of the loop if command is nil (EOF)
      break unless command

      process_command(command)
    end

    # Display goodbye message when exiting
    @output.puts("\nThank you for using the Parking System. Goodbye!\n")
  end

  private

  # Read a command from the input stream
  # @return [String, nil] The command string or nil if EOF
  def read_command
    input = @input.gets
    return nil unless input

    input.chomp
  end

  # Process a command
  # @param command [String] The command to process
  def process_command(command) # rubocop:disable Metrics/MethodLength
    # Normalize the command by trimming whitespace
    normalized_command = command.strip

    # Handle empty commands
    if normalized_command.empty?
      @output.puts(formatter.format_error('Invalid command. Type \'help\' for available commands.'))
      return
    end

    # Process exit command directly
    if normalized_command.downcase == 'exit'
      stop
      return
    end

    # Process all other commands
    result = @command_handler.execute_command(normalized_command)

    # Display the result
    if result[:success]
      @output.puts("\n#{result[:message]}")
    else
      @output.puts(formatter.format_error(result[:message]))
    end
  end
end
