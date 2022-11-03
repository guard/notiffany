require "notiffany/notifier"

module Notiffany
  RSpec.describe Notifier, exclude_stubs: [Nenv, Notifier::Env] do
    let(:options) { { notify: enabled } }
    subject { described_class.new(options) }

    let(:logger) { instance_double(Logger, :level= => nil, debug: nil) }
    let(:enabled) { true }

    # Use tmux as base, because it has both :turn_on and :turn_off
    %w(foo bar baz).each do |name|
      let(name.to_sym) do
        class_double(
          "Notiffany::Notifier::Tmux",
          name: name
        )
      end
    end

    let(:foo_object) { instance_double("Notiffany::Notifier::Tmux") }
    let(:bar_object) { instance_double("Notiffany::Notifier::Tmux") }

    let(:env) { instance_double(Notifier::Env) }
    let(:detected) { instance_double("Notiffany::Notifier::Detected") }

    before do
      allow(Notifier::Env).to receive(:new).with("notiffany").and_return(env)

      allow(Logger).to receive(:new).and_return(logger)

      # DEFAULTS FOR TESTS
      allow(env).to receive(:notify?).and_return(true)
      allow(env).to receive(:notify_active?).and_return(false)
      allow(env).to receive(:notify_active=)
      allow(env).to receive(:notify_pid).and_return($$)
      allow(env).to receive(:notify_pid=).with($$)

      allow(described_class::Detected).to receive(:new).
        with(described_class::SUPPORTED, 'notiffany', logger).
        and_return(detected)

      allow(detected).to receive(:add)
      allow(detected).to receive(:reset)
      allow(detected).to receive(:detect)
      allow(detected).to receive(:available).and_return([foo_object])

      allow(foo_object).to receive(:title).and_return("Foo")
      allow(bar_object).to receive(:title).and_return("Bar")
    end

    after do
      # This is ok, because it shows singletons are NOT ok
      described_class.instance_variable_set(:@detected, nil)
    end

    describe "#initialize" do
      before do
        allow(env).to receive(:notify?).and_return(env_enabled)
      end

      context "when enabled with environment" do
        let(:env_enabled) { true }

        context "when enabled with options" do
          let(:options) { { notify: true } }
          it "assigns a pid" do
            expect(env).to receive(:notify_pid=).with($$)
            subject
          end

          it "autodetects" do
            expect(detected).to receive(:detect)
            subject
          end
        end

        context "when no options given" do
          let(:options) { {} }
          it "assigns a pid" do
            expect(env).to receive(:notify_pid=).with($$)
            subject
          end

          it "autodetects" do
            expect(detected).to receive(:detect)
            subject
          end
        end

        context "when disabled with options" do
          let(:options) { { notify: false } }
          it "assigns a pid anyway" do
            expect(env).to receive(:notify_pid=).with($$)
            subject
          end

          it "does not autodetect" do
            expect(detected).to_not receive(:detect)
            subject
          end
        end
      end

      context "when disabled with environment" do
        let(:env_enabled) { false }
        pending
      end

      context "with custom notifier config" do
        let(:env_enabled) { true }
        let(:notifiers) { { foo: { bar: :baz } } }
        let(:options) { { notifiers: notifiers } }

        before do
          allow(detected).to receive(:available).and_return([])
          allow(env).to receive(:notify?).and_return(enabled)
        end

        context "when child process" do
          let(:enabled) { true }
          before { allow(env).to receive(:notify_pid).and_return($$ + 100) }
          it "works" do
            subject
          end
        end

        context "when not connected" do
          context "when disabled" do
            let(:enabled) { false }

            it "does not add anything" do
              expect(detected).to_not receive(:add)
              subject
            end
          end

          context "when enabled" do
            let(:enabled) { true }

            context "when supported" do
              let(:name) { foo }

              context "when available" do
                it "adds the notifier to the notifications" do
                  expect(detected).to receive(:add).with(:foo, { bar: :baz })
                  subject
                end
              end
            end
          end
        end

        context "when connected" do
          before do
            allow(env).to receive(:notify?).and_return(enabled)
          end

          context "when disabled" do
            let(:enabled) { false }

            it "does not add anything" do
              expect(detected).to_not receive(:add)
              subject
            end
          end

          context "when enabled" do
            let(:enabled) { true }

            context "when :off" do
              let(:notifiers) { { off: {} } }
              it "turns off the notifier" do
                expect(subject).to_not be_active
              end
            end

            context "when supported" do
              let(:name) { foo }

              context "when available" do
                it "adds the notifier to the notifications" do
                  expect(detected).to receive(:add).
                    with(:foo, { bar: :baz })
                  subject
                end
              end
            end
          end
        end
      end
    end

    describe ".disconnect" do
      before do
        allow(env).to receive(:notify_pid=)
      end

      it "resets detector" do
        expect(detected).to receive(:reset)
        subject.disconnect
      end

      it "reset the pid env var" do
        expect(env).to receive(:notify_pid=).with(nil)
        subject.disconnect
      end
    end

    describe ".turn_on" do
      let(:options) { {} }

      before do
        allow(detected).to receive(:available).and_return(available)

        subject
        allow(env).to receive(:notify_active?).and_return(true)
        subject.turn_off
        allow(env).to receive(:notify_active?).and_return(false)
      end

      context "with available notifiers" do
        let(:available) { [foo_object] }

        context "when a child process" do
          before { allow(env).to receive(:notify_pid).and_return($$ + 100) }
          it { expect { subject.turn_on }.to raise_error(/Only notify()/) }
        end

        context "without silent option" do
          let(:options) { { silent: false } }
          it "shows the used notifications" do
            expect(logger).to receive(:debug).
              with "Notiffany is using Foo to send notifications."
            subject.turn_on(options)
          end
        end

        context "with silent option" do
          let(:options) { { silent: true } }
          it "does not show activated notifiers" do
            expect(logger).to_not receive(:info)
            subject.turn_on(options)
          end
        end
      end

      context "without available notifiers" do
        let(:available) { [] }
        it "sets mode to active" do
          expect(env).to receive(:notify_active=).with(true)
          subject.turn_on(options)
        end
      end
    end

    describe ".turn_off" do
      before do
        allow(env).to receive(:notify?).and_return(true)

        allow(detected).to receive(:available).and_return(available)
      end

      context "with no available notifiers" do
        let(:available) { [] }
        it "is not active" do
          subject
          expect(subject).to_not be_active
        end
      end

      context "with available notifiers" do
        let(:available) { [foo_object] }

        before do
          subject
        end

        context "when a child process" do
          before { allow(env).to receive(:notify_pid).and_return($$ + 100) }
          it { expect { subject.turn_off }.to raise_error(/Only notify()/) }
        end

        it "turns off each notifier" do
          allow(env).to receive(:notify_active?).and_return(true)
          expect(foo_object).to receive(:turn_off)
          subject.turn_off
        end
      end
    end

    describe ".enabled?" do
      before do
        allow(env).to receive(:notify?).and_return(enabled)
      end

      context "when enabled" do
        let(:enabled) { true }
        it { is_expected.to be_enabled }
      end

      context "when disabled" do
        let(:enabled) { false }
        it { is_expected.not_to be_enabled }
      end
    end

    describe ".notify" do
      context "with multiple notifiers" do
        before do
          allow(detected).to receive(:available).
            and_return([foo_object, bar_object])

          allow(foo).to receive(:new).with(color: true).and_return(foo_object)
          allow(bar).to receive(:new).with({}).and_return(bar_object)
          allow(env).to receive(:notify?).and_return(enabled)
        end

        # TODO: deprecate
        context "when not connected" do
          let(:enabled) { true }

          before do
            allow(env).to receive(:notify_active?).and_return(false)
          end

          context "when a child process" do
            before { allow(env).to receive(:notify_pid).and_return($$ + 100) }

            before do
              allow(foo_object).to receive(:notify)
              allow(bar_object).to receive(:notify)
            end

            it "sends notifications" do
              expect(foo_object).to receive(:notify).with("Hello", { foo: "bar" })
              expect(bar_object).to receive(:notify).with("Hello", { foo: "bar" })
              subject.notify("Hello", foo: "bar")
            end

            it "shows a deprecation message" do
              pending
              expect(logger).to receive(:deprecation).
                with(/Notifier.notify\(\) without a prior Notifier.connect/)

              subject.notify("Hello", foo: "bar")
            end
          end
        end

        context "when connected" do
          before do
            subject
            allow(env).to receive(:notify_active?).and_return(enabled)
          end

          context "when enabled" do
            let(:enabled) { true }

            it "sends notifications" do
              expect(foo_object).to receive(:notify).with("Hello", { foo: "bar" })
              expect(bar_object).to receive(:notify).with("Hello", { foo: "bar" })
              subject.notify("Hello", foo: "bar")
            end

            context "when a child process" do
              before { allow(env).to receive(:notify_pid).and_return($$ + 100) }
              it "sends notifications" do
                expect(foo_object).to receive(:notify).with("Hello", { foo: "bar" })
                expect(bar_object).to receive(:notify).with("Hello", { foo: "bar" })
                subject.notify("Hello", foo: "bar")
              end
            end
          end

          context "when disabled" do
            let(:enabled) { false }

            it "does not send notifications" do
              expect(foo_object).to_not receive(:notify)
              expect(bar_object).to_not receive(:notify)
              subject.notify("Hi to everyone")
            end

            context "when a child process" do
              before { allow(env).to receive(:notify_pid).and_return($$ + 100) }
              it "sends notifications" do
                expect(foo_object).to_not receive(:notify)
                expect(bar_object).to_not receive(:notify)
                subject.notify("Hello", foo: "bar")
              end
            end
          end
        end
      end
    end

    describe "#available" do
      context "when connected" do
        let(:options) { { notify: true } }
        before do
          subject
          allow(env).to receive(:notify_active?).and_return(true)
          allow(detected).to receive(:available).and_return(available)
        end

        context "with available notifiers" do
          let(:available) { [foo_object, bar_object] }
          it "returns a list of available notifier info" do
            expect(subject.available).to eq([foo_object, bar_object])
          end
        end
      end
    end
  end
end
