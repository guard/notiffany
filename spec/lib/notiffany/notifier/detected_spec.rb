require "notiffany/notifier/detected"

module Notiffany
  class Notifier
    RSpec.describe YamlEnvStorage do
      let(:subject) { YamlEnvStorage.new("notiffany_tests_foo") }
      describe "#notifiers" do

        context "when set to empty array" do
          before { subject.notifiers = [] }
          specify { expect(subject.notifiers).to be_empty }
        end

        context "when set to nil" do
          before { subject.notifiers = nil }
          specify { expect(subject.notifiers).to be_empty }
        end

        context "when env is empty" do
          before { ENV['NOTIFFANY_TESTS_FOO_NOTIFIERS'] = nil }
          specify { expect(subject.notifiers).to be_empty }
        end
      end
    end

    RSpec.describe(Detected, exclude_stubs: [YamlEnvStorage]) do
      let(:logger) { double("Logger", debug: nil) }

      subject { described_class.new(supported, "notiffany_tests", logger) }

      let(:env) { instance_double(YamlEnvStorage) }

      let(:foo_mod) { double("foo_mod") }
      let(:bar_mod) { double("bar_mod") }
      let(:baz_mod) { double("baz_mod") }

      let(:foo_obj) { double("foo_obj") }
      let(:baz_obj) { double("baz_obj") }

      let(:supported) { [foo: foo_mod, baz: baz_mod] }

      before do
        allow(YamlEnvStorage).to receive(:new).and_return(env)

        allow(env).to receive(:notifiers) do
          fail "stub me: notifiers"
        end

        allow(env).to receive(:notifiers=) do |args|
          fail "stub me: notifiers=(#{args.inspect})"
        end
      end

      describe ".available" do
        context "with detected notifiers" do
          let(:available) do
            [
              { name: :foo, options: {} },
              { name: :baz, options: { opt1: 3 } }
            ]
          end

          let(:expected) { [foo_obj, baz_obj] }

          before do
            allow(foo_mod).to receive(:new).and_return(foo_obj)
            allow(baz_mod).to receive(:new).and_return(baz_obj)
            allow(env).to receive(:notifiers).and_return(available)
          end

          it "returns hash with detected notifier options" do
            expect(subject.available).to eq(expected)
          end
        end
      end

      describe ".add" do
        before do
          allow(env).to receive(:notifiers).and_return([])
        end
        context "with no detected notifiers" do
          context "when unknown" do
            it "does not add the library" do
              expect(env).to_not receive(:notifiers=)
              expect { subject.add(:unknown, {}) }.
                to raise_error(Notifier::Detected::UnknownNotifier)
            end
          end
        end
      end

      describe ".detect" do
        context "with some detected notifiers" do
          before do
            allow(env).to receive(:notifiers).and_return([])

            allow(foo_mod).to receive(:new).and_return(foo_obj)
            allow(baz_mod).to receive(:new).
              and_raise(Notifier::Base::UnavailableError, "some failure")
          end

          let(:detected) { [{ name: :foo, options: {} }] }

          it "add detected notifiers to available" do
            expect(env).to receive(:notifiers=) do |args|
              expect(args).to eq(detected)
            end

            allow(env).to receive(:notifiers).and_return([], [], detected)
            subject.detect
          end
        end

        context "without any detected notifiers" do
          before do
            allow(env).to receive(:notifiers).and_return([])

            allow(foo_mod).to receive(:new).
              and_raise(Notifier::Base::UnavailableError, "some error")
            allow(baz_mod).to receive(:new).
              and_raise(Notifier::Base::UnavailableError, "some error")
          end

          let(:error) { described_class::NoneAvailableError }
          let(:msg) { /could not detect any of the supported notification/ }
          it { expect { subject.detect }.to raise_error(error, msg) }
        end
      end

      describe ".reset" do
        before do
          allow(env).to receive(:notifiers=)
        end

        it "resets the detected notifiers" do
          expect(env).to receive(:notifiers=).with([])
          subject.reset
        end
      end
    end
  end
end
