require "rbconfig"

module Notiffany
  class Notifier
    class Base
      HOSTS = {
        darwin:  "Mac OS X",
        linux:   "Linux",
        freebsd: "FreeBSD",
        openbsd: "OpenBSD",
        sunos:   "SunOS",
        solaris: "Solaris",
        mswin:   "Windows",
        mingw:   "Windows",
        cygwin:  "Windows"
      }

      ERROR_ADD_GEM_AND_RUN_BUNDLE = "Please add \"gem '%s'\" to your Gemfile "\
        "and run your app with \"bundle exec\"."

      class RequireFailed < RuntimeError
      end

      class UnavailableError < RuntimeError
      end

      class UnsupportedPlatform < UnavailableError
      end

      def initialize(ui, opts = {})
        options = opts.dup
        options.delete(:silent)
        @options =
          { title: "Notiffany" }.
          merge(self.class.const_get(:DEFAULTS)).
          merge(options).freeze

        @ui = ui
        @images_path = Pathname.new(__FILE__).dirname + "../../../images"

        _check_host_supported
        _require_gem
        _check_available(@options)
      end

      def title
        self.class.to_s[/.+::(\w+)$/, 1]
      end

      def name
        title.gsub(/([a-z])([A-Z])/, '\1_\2').downcase
      end

      def notify(message, opts = {})
        new_opts = _notify_options(opts).freeze
        _perform_notify(message, new_opts)
      end

      def _image_path(image)
        images = [:failed, :pending, :success, :guard]
        images.include?(image) ? @images_path.join("#{image}.png").to_s : image
      end

      private

      # Override if necessary
      def _gem_name
        name
      end

      # Override if necessary
      def _supported_hosts
        :all
      end

      # Override
      def _check_available(_options)
        fail NotImplementedError
      end

      # Override
      def _perform_notify(_message, _opts)
        fail NotImplementedError
      end

      def _notification_type(image)
        [:failed, :pending, :success].include?(image) ? image : :notify
      end

      def _notify_options(overrides = {})
        opts = @options.merge(overrides)
        img_type = opts.fetch(:image, :success)
        opts[:type] ||= _notification_type(img_type)
        opts[:image] = _image_path(img_type)
        opts
      end

      def _check_host_supported
        return if _supported_hosts == :all
        expr = /#{_supported_hosts * '|'}/
        fail UnsupportedPlatform, name unless RbConfig::CONFIG["host_os"][expr]
      end

      def _require_gem
        Kernel.require _gem_name unless _gem_name.nil?
      rescue LoadError, NameError
        fail RequireFailed, _gem_name
      end
    end
  end
end
