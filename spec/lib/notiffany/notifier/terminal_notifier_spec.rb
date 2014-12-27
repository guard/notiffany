require "notiffany/notifier/terminal_notifier"

module Notiffany
  RSpec.describe Notifier::TerminalNotifier do
    let(:ui) { double("ui") }
    let(:options) { {} }
    let(:os) { "solaris" }
    subject { described_class.new(ui, options) }

    before do
      allow(Kernel).to receive(:require)
      allow(RbConfig::CONFIG).to receive(:[]).with("host_os") { os }

      stub_const "TerminalNotifier::Guard", double(available?: true)
    end

    describe ".available?" do
      context "host is not supported" do
        let(:os) { "mswin" }

        it "fails" do
          expect { subject }.to raise_error(Notifier::Base::UnavailableError)
        end
      end

      context "host is supported" do
        let(:os) { "darwin" }
        it "works" do
          subject
        end
      end
    end

    describe "#notify" do
      let(:os) { "darwin" }
      context "with options passed at initialization" do
        let(:options) { { title: "Hello", silent: true } }

        it "uses these options by default" do
          expect(TerminalNotifier::Guard).to receive(:execute).
            with(false, title: "Hello", type: :success, message: "any message")

          subject.notify("any message")
        end

        it "overwrites object options with passed options" do
          expect(::TerminalNotifier::Guard).to receive(:execute).
            with(
              false,
              title: "Welcome",
              type: :success,
              message: "any message")

          subject.notify("any message", title: "Welcome")
        end
      end

      it "should call the notifier." do
        expect(::TerminalNotifier::Guard).to receive(:execute).
          with(false,
               title: "any title",
               type: :success,
               message: "any message")

        subject.notify("any message", title: "any title")
      end

      it "should allow the title to be customized" do
        expect(::TerminalNotifier::Guard).to receive(:execute).
          with(false,
               title: "any title",
               message: "any message",
               type: :error)

        subject.notify("any message", type: :error, title: "any title")
      end

      context "without a title set" do
        it "should show the app name in the title" do
          expect(::TerminalNotifier::Guard).to receive(:execute).
            with(false,
                 title: "FooBar Success",
                 type: :success,
                 message: "any message")

          # TODO: why would anyone set the title explicitly to nil? and also
          # expect it to be set to a default value?
          subject.notify("any message", title: nil, app_name: "FooBar")
        end
      end
    end

  end
end
