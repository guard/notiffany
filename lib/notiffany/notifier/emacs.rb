require "notiffany/notifier/base"
require "shellany/sheller"

module Notiffany
  class Notifier
    # Send a notification to Emacs with emacsclient
    # (http://www.emacswiki.org/emacs/EmacsClient).
    #
    class Emacs < Base
      DEFAULTS = {
        client:    "emacsclient",
        success:   "ForestGreen",
        failed:    "Firebrick",
        default:   "Black",
        fontcolor: "White",
      }

      private

      def _check_available(options)
        cmd = "#{options[:client]} --eval '1' 2> #{IO::NULL} || echo 'N/A'"
        stdout = Shellany::Sheller.stdout(cmd)
        fail UnavailableError if stdout.nil?
        fail UnavailableError if %w(N/A 'N/A').include?(stdout.chomp)
      end

      # Shows a system notification.
      #
      # @param [String] type the notification type. Either 'success',
      #   'pending', 'failed' or 'notify'
      # @param [String] title the notification title
      # @param [String] message the notification message body
      # @param [String] image the path to the notification image
      # @param [Hash] opts additional notification library options
      # @option opts [String] success the color to use for success
      #   notifications (default is 'ForestGreen')
      # @option opts [String] failed the color to use for failure
      #   notifications (default is 'Firebrick')
      # @option opts [String] pending the color to use for pending
      #   notifications
      # @option opts [String] default the default color to use (default is
      #   'Black')
      # @option opts [String] client the client to use for notification
      #   (default is 'emacsclient')
      # @option opts [String, Integer] priority specify an int or named key
      #   (default is 0)
      #
      def _perform_notify(_message, opts = {})
        color     = _emacs_color(opts[:type], opts)
        fontcolor = _emacs_color(:fontcolor, opts)
        elisp = <<-EOF.gsub(/\s+/, " ").strip
          (set-face-attribute 'mode-line nil
               :background "#{color}"
               :foreground "#{fontcolor}")
        EOF

        _run_cmd(opts[:client], "--eval", elisp)
      end

      # Get the Emacs color for the notification type.
      # You can configure your own color by overwrite the defaults.
      #
      # @param [String] type the notification type
      # @param [Hash] options aditional notification options
      #
      # @option options [String] success the color to use for success
      # notifications (default is 'ForestGreen')
      #
      # @option options [String] failed the color to use for failure
      # notifications (default is 'Firebrick')
      #
      # @option options [String] pending the color to use for pending
      # notifications
      #
      # @option options [String] default the default color to use (default is
      # 'Black')
      #
      # @return [String] the name of the emacs color
      #
      def _emacs_color(type, options = {})
        default = options.fetch(:default, DEFAULTS[:default])
        options.fetch(type.to_sym, default)
      end

      def _run_cmd(cmd, *args)
        Shellany::Sheller.run(cmd, *args)
      end

      def _gem_name
        nil
      end
    end
  end
end
