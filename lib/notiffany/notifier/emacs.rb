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

      class Client
        def initialize(options)
          @client = options[:client]

          if available?
            elisp = <<-EOF
(if (fboundp 'notiffany-notify)
    (print "Notiffany Emacs notifier: notiffany-notify is defined, using that")
  (defun notiffany-notify (color bgcolor)
    (unless (boundp 'notiffany-original-background)
      (setq notiffany-original-background (face-background 'mode-line)))
    (unless (boundp 'notiffany-original-foreground)
      (setq notiffany-original-foreground (face-foreground 'mode-line)))
    (set-face-attribute 'mode-line nil
                        :background bgcolor
                        :foreground color)
    (run-at-time "10 sec" nil (lambda ()
                                (message "resetting mode-line background to '%s'" notiffany-original-background)
                                (message "resetting mode-line foreground to '%s'" notiffany-original-foreground)
                                (set-face-attribute 'mode-line nil
                                                    :background notiffany-original-background
                                                    :foreground notiffany-original-foreground)))))
EOF
          end
        end

        def available?
          emacs_eval("'1'")
        end

        def notify(color, bgcolor)
          elisp = <<-EOF.gsub(/\s+/, " ").strip
            (notiffany-notify "#{bgcolor}" "#{color}")
          EOF
          emacs_eval(elisp)
        end

        private

        def emacs_eval(code)
          Shellany::Sheller.run(@client, "--eval", code)
        end
      end

      private

      def _gem_name
        nil
      end

      def _check_available(options)
        return if Client.new(options).available?
        fail UnavailableError, "Emacs client failed"
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
        Client.new(opts).notify(fontcolor, color)
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
    end
  end
end
