require "notiffany/notifier/tmux"

module Notiffany
  class Notifier
    RSpec.describe Tmux::Client do
      let(:sheller) { class_double("Shellany::Sheller") }

      subject { described_class.new(nil) }

      before do
        stub_const("Shellany::Sheller", sheller)
      end

      describe ".version" do
        context "when tmux is not installed" do
          it "fails" do
            allow(sheller).to receive(:stdout).and_return(nil)
            expect do
              described_class.version
            end.to raise_error(Base::UnavailableError)
          end
        end

        context "when 'tmux -v' doesn't contain float-like string" do
          it "fails" do
            allow(sheller).to receive(:stdout).and_return('master')
            expect do
              described_class.version
            end.to raise_error(Base::UnavailableError)
          end
        end
      end

      describe "#clients" do
        context "when :all is given" do
          subject { described_class.new(:all) }

          it "removes null terminal" do
            allow(sheller).to receive(:stdout).
              with("tmux list-clients -F '\#{client_tty}'") do
              "/dev/ttys001\n/dev/ttys000\n(null)\n"
            end

            clients = subject.clients

            expect(clients).to include "/dev/ttys001"
            expect(clients).to include "/dev/ttys000"
            expect(clients).not_to include "(null)"
          end
        end
      end

      describe "#display" do
        it "displays text in given area" do
          expect(sheller).to receive(:run).with("tmux display 'foo'")
          subject.display_message("foo")
        end

        context "when displaying on all clients" do
          subject { described_class.new(:all) }

          it "displays on every client" do
            allow(sheller).to receive(:stdout).
              with("tmux list-clients -F '\#{client_tty}'") do
              "/dev/ttys001\n"
            end

            expect(sheller).to receive(:run)
              .with("tmux display -c /dev/ttys001 'foo'")
            subject.display_message("foo")
          end
        end
      end

      describe "#message_fg=" do
        it "sets message fg color" do
          expect(sheller).to receive(:run).with("tmux set -q message-fg green")
          subject.message_fg = "green"
        end
      end

      describe "#message_bg=" do
        it "sets message bg color" do
          expect(sheller).to receive(:run).with("tmux set -q message-bg white")
          subject.message_bg = "white"
        end
      end

      describe "#display_time=" do
        it "sets display time" do
          expect(sheller).to receive(:run).with("tmux set -q display-time 5000")
          subject.display_time = 5000
        end
      end

      describe "#title=" do
        it "sets terminal title" do
          expect(sheller).to receive(:run).
            with("tmux set -q set-titles-string 'foo'")
          subject.title = "foo"
        end
      end
    end

    RSpec.describe Tmux::Session do
      let(:all) { instance_double(Tmux::Client) }
      let(:tty) { instance_double(Tmux::Client) }
      let(:sheller) { class_double("Shellany::Sheller") }

      before do
        allow(Tmux::Client).to receive(:new).with(:all).and_return(all)
        allow(Tmux::Client).to receive(:new).with("tty").and_return(tty)
        stub_const("Shellany::Sheller", sheller)
      end

      describe "#start" do
        before do
          allow(all).to receive(:clients).and_return(%w(tty))
          allow(tty).to receive(:parse_options).and_return({})
        end

        it "sets options" do
          subject
        end
      end

      describe "#close" do
        before do
          allow(all).to receive(:clients).and_return(%w(tty))
          allow(tty).to receive(:parse_options).and_return({})
        end

        it "restores the tmux options" do
          allow(tty).to receive(:unset).with("status-left-bg", nil)
          allow(tty).to receive(:unset).with("status-left-fg", nil)
          allow(tty).to receive(:unset).with("status-right-bg", nil)
          allow(tty).to receive(:unset).with("status-right-fg", nil)
          allow(tty).to receive(:unset).with("message-bg", nil)
          allow(tty).to receive(:unset).with("message-fg", nil)
          allow(tty).to receive(:unset).with("display-time", nil)
          allow(tty).to receive(:unset).with("display-time", nil)
          subject.close
        end
      end
    end

    RSpec.describe Tmux do
      let(:tmux_version) { 1.9 }

      let(:options) { {} }
      let(:os) { "solaris" }
      let(:tmux_env) { true }
      subject { described_class.new(options) }

      let(:client) { instance_double(Tmux::Client) }
      let(:session) { instance_double(Tmux::Session) }

      let(:sheller) { class_double("Shellany::Sheller") }

      before do
        allow(Kernel).to receive(:require)
        allow(RbConfig::CONFIG).to receive(:[]).with("host_os") { os }

        allow(ENV).to receive(:key?).with("TMUX").and_return(tmux_env)

        allow(Tmux::Client).to receive(:new).and_return(client)
        allow(Tmux::Client).to receive(:version).and_return(tmux_version)

        allow(Tmux::Session).to receive(:new).and_return(session)
        allow(session).to receive(:close)

        stub_const("Shellany::Sheller", sheller)
      end

      after do
        described_class.send(:_end_session) if described_class.send(:_session)
      end

      describe "#initialize" do
        context "when the TMUX environment variable is set" do
          let(:tmux_env) { true }

          context "with a recent version of tmux" do
            let(:tmux_version) { 2.0 }
            it "works" do
              subject
            end
          end

          context "with an outdated version of tmux" do
            let(:tmux_version) { 1.8 }
            it "fails" do
              expect { subject }.
                to raise_error(
                  Base::UnavailableError,
                  /way too old \(1.8\)/
                )
            end
          end

          context "without tmux" do
            it "fails" do
              allow(Tmux::Client).to receive(:version).
                and_raise(Base::UnavailableError, "Could not find tmux")
              expect { subject }.
                to raise_error(
                  Base::UnavailableError,
                  "Could not find tmux"
                )
            end
          end
        end

        context "when the TMUX environment variable is not set" do
          let(:tmux_env) { false }
          it "fails" do
            expect { subject }.
              to raise_error(
                Base::UnavailableError,
                /only available inside a TMux session/
              )
          end
        end
      end

      describe "#notify" do
        before do
          allow(client).to receive(:set).with("status-left-bg", anything)
          allow(client).to receive(:display_time=)
          allow(client).to receive(:message_fg=)
          allow(client).to receive(:message_bg=)
          allow(client).to receive(:display_message)
        end

        context "with options passed at initialization" do
          let(:options) do
            { success: "rainbow",
              silent: true,
              starting: "vanilla" }
          end

          it "uses these options by default" do
            expect(client).to receive(:set).with("status-left-bg", "rainbow")
            subject.notify("any message", type: :success)
          end

          it "overwrites object options with passed options" do
            expect(client).to receive(:set).with("status-left-bg", "black")
            subject.notify("any message", type: :success, success: "black")
          end

          it "uses the initialization options for custom types by default" do
            expect(client).to receive(:set).with("status-left-bg", "vanilla")
            subject.notify("any message", type: :starting)
          end
        end

        it "sets the tmux status bar color to green on success" do
          expect(client).to receive(:set).with("status-left-bg", "green")
          subject.notify("any message", type: :success)
        end

        context "when success: black is passed in as an option" do
          let(:options) { { success: "black" } }

          it "on success it sets the tmux status bar color to black" do
            expect(client).to receive(:set).with("status-left-bg", "black")
            subject.notify("any message", options.merge(type: :success))
          end
        end

        it "sets the tmux status bar color to red on failure" do
          expect(client).to receive(:set).with("status-left-bg", "red")
          subject.notify("any message", type: :failed)
        end

        it "should set the tmux status bar color to yellow on pending" do
          expect(client).to receive(:set).with("status-left-bg", "yellow")
          subject.notify("any message", type: :pending)
        end

        it "sets the tmux status bar color to green on notify" do
          expect(client).to receive(:set).with("status-left-bg", "green")
          subject.notify("any message", type: :notify)
        end

        it "sets the tmux status bar color to default color on a custom type" do
          expect(client).to receive(:set).with("status-left-bg", "black")
          subject.notify("any message", type: :custom, default: "black")
        end

        it "sets the tmux status bar color to default color on a custom type" do
          expect(client).to receive(:set).with("status-left-bg", "green")
          subject.notify("any message", type: :custom)
        end

        it "sets the tmux status bar color to passed color on a custom type" do
          expect(client).to receive(:set).with("status-left-bg", "black")
          subject.notify("any message", type: :custom, custom: "black")
        end

        context "when right status bar is passed in as an option" do
          it "should set the right tmux status bar color on success" do
            expect(client).to receive(:set).with("status-right-bg", "green")
            subject.notify("any message", color_location: "status-right-bg")
          end
        end

        it "does not change colors when the change_color flag is disabled" do
          expect(client).to_not receive(:set)
          subject.notify("any message", change_color: false)
        end

        it "calls display_message if the display_message flag is set" do
          expect(client).to receive(:display_message).
            with("Notiffany - any message")

          subject.notify("any message", type: :notify, display_message: true)
        end

        context "when the display_message flag is not set" do
          it "does not call display_message" do
            expect(client).to_not receive(:display_message)
            subject.notify("any message")
          end
        end

        it "calls display_title if the display_title flag is set" do
          expect(client).to receive(:title=).with("Notiffany - any message")
          subject.notify("any message", type: :notify, display_title: true)
        end

        it "does not call display_title if the display_title flag is not set" do
          expect(client).to_not receive(:display)
          subject.notify("any message")
        end

        context "when color_location is passed with an array" do
          let(:options) do
            { color_location: %w(status-left-bg pane-border-fg) }
          end

          it "should set the color on multiple tmux settings" do
            expect(client).to receive(:set).with("status-left-bg", "green")
            expect(client).to receive(:set).with("pane-border-fg", "green")
            subject.notify("any message", options)
          end
        end

        context "with display_title option" do
          let(:options) do
            {
              success: "rainbow",
              silent: true,
              starting: "vanilla",
              display_title: true
            }
          end

          before do
            allow(client).to receive(:title=)
            allow(client).to receive(:set).with("status-left-bg", anything)
          end

          it "displays the title" do
            expect(client).to receive(:title=).with("any title - any message")
            subject.notify "any message", type: "success", title: "any title"
          end

          it "shows only the first line of the message" do
            expect(client).to receive(:title=).with("any title - any message")
            subject.notify(
              "any message\nline two",
              type: "success",
              title: "any title"
            )
          end

          context "with success message type options" do
            it "formats the message" do
              expect(client).to receive(:title=).
                with("[any title] => any message")

              subject.notify(
                "any message\nline two",
                options.merge(
                  type: "success",
                  title: "any title",
                  success_title_format: "[%s] => %s",
                  default_title_format: "(%s) -> %s"
                )
              )
            end
          end

          context "with pending message type options" do
            it "formats the message" do
              expect(client).to receive(:title=).
                with("[any title] === any message")
              subject.notify(
                "any message\nline two",
                type: "pending",
                title: "any title",
                pending_title_format: "[%s] === %s",
                default_title_format: "(%s) -> %s"
              )
            end
          end

          context "with failed message type options" do
            it "formats the message" do
              expect(client).to receive(:title=).
                with("[any title] <=> any message")

              subject.notify(
                "any message\nline two",
                type: "failed",
                title: "any title",
                failed_title_format: "[%s] <=> %s",
                default_title_format: "(%s) -> %s"
              )
            end
          end
        end

        it "sets the display-time" do
          expect(client).to receive(:display_time=).with(3000)

          subject.notify(
            "any message",
            type: "success",
            display_message: true,
            title: "any title",
            timeout: 3)
        end

        it "displays the message" do
          expect(client).to receive(:display_message).
            with("any title - any message")

          subject.notify(
            "any message",
            display_message: true,
            type: "success",
            title: "any title"
          )
        end

        it "handles line-breaks" do
          expect(client).to receive(:display_message).
            with("any title - any message xx line two")

          subject.notify(
            "any message\nline two",
            type: "success",
            display_message: true,
            title: "any title",
            line_separator: " xx ")
        end

        context "with success message type options" do
          it "formats the message" do
            expect(client).to receive(:display_message).
              with("[any title] => any message - line two")

            subject.notify(
              "any message\nline two",
              type: "success",
              title: "any title",
              display_message: true,
              success_message_format: "[%s] => %s",
              default_message_format: "(%s) -> %s")
          end

          it "sets the foreground color based on the type for success" do
            allow(client).to receive(:message_fg=).with("green")

            subject.notify(
              "any message",
              type: "success",
              title: "any title",
              display_message: true,
              success_message_color: "green")
          end

          it "sets the background color" do
            allow(client).to receive(:set).with("status-left-bg", :blue)
            allow(client).to receive(:message_bg=).with("blue")

            subject.notify(
              "any message",
              type: "success",
              title: "any title",
              success: :blue)
          end
        end

        context "with pending message type options" do
          let(:notify_opts) do
            {
              type: "pending",
              title: "any title",
              display_message: true
            }
          end

          before do
          end

          it "formats the message" do
            # expect(sheller).to receive(:run).
            #  with("tmux display"\
            #       ' \'\'').once {}
            #
            expect(client).to receive(:display_message).
              with("[any title] === any message - line two")

            subject.notify(
              "any message\nline two",
              notify_opts.merge(
                pending_message_format: "[%s] === %s",
                default_message_format: "(%s) -> %s")
            )
          end

          it "sets the foreground color" do
            expect(client).to receive(:message_fg=).with("blue")

            subject.notify(
              "any message",
              notify_opts.merge(pending_message_color: "blue")
            )
          end

          it "sets the background color" do
            expect(client).to receive(:message_bg=).with(:white)
            subject.notify("any message", notify_opts.merge(pending: :white))
          end
        end

        context "with failed message type options" do
          let(:notify_opts) do
            {
              type: "failed",
              title: "any title",
              display_message: true,
              failed_message_color: "red"
            }
          end

          before do
            allow(client).to receive(:set).with("status-left-bg", anything)
            allow(client).to receive(:message_fg=)
            allow(client).to receive(:message_bg=)
            allow(client).to receive(:display_message)
          end

          it "formats the message" do
            expect(client).to receive(:display_message).
              with("[any title] <=> any message - line two")

            subject.notify(
              "any message\nline two",
              notify_opts.merge(
                failed_message_format: "[%s] <=> %s",
                default_message_format: "(%s) -> %s")
            )
          end

          it "sets the foreground color" do
            expect(client).to receive(:message_fg=).with("red")
            subject.notify("any message", notify_opts)
          end

          it "sets the background color" do
            expect(client).to receive(:message_bg=).with(:black)
            subject.notify("any message", notify_opts.merge(failed: :black))
          end
        end
      end

      describe "#turn_on" do
        context "when on" do
          before do
            subject.turn_on
          end

          it "fails" do
            expect do
              subject.turn_on
            end.to raise_error("Already turned on!")
          end
        end
      end

      describe "#turn_off" do
        context "when on" do
          before do
            subject.turn_on
          end

          it "closes the session" do
            expect(session).to receive(:close)
            subject.turn_off
          end
        end

        context "when off" do
          before do
            subject.turn_on
            subject.turn_off
          end

          it "fails" do
            expect do
              subject.turn_off
            end.to raise_error("Already turned off!")
          end
        end
      end
    end
  end
end
