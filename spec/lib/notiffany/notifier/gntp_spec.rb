require "notiffany/notifier/gntp"

module Notiffany
  RSpec.describe Notifier::GNTP do
    let(:gntp) { double("GNTP").as_null_object }

    let(:ui) { double("UI") }
    let(:options) { {} }
    let(:os) { "solaris" }
    subject { described_class.new(ui, options) }

    before do
      stub_const "GNTP", gntp
      allow(Kernel).to receive(:require)
      allow(RbConfig::CONFIG).to receive(:[]).with("host_os") { os }
    end

    describe ".available?" do
      context "host is not supported" do
        let(:os) { "foobar" }

        it "fails" do
          expect { subject }.to raise_error(Notifier::Base::UnsupportedPlatform)
        end
      end

      context "host is supported" do
        let(:os) { "darwin" }

        it "requires ruby_gntp" do
          expect(Kernel).to receive(:require).with("ruby_gntp")
          subject
        end
      end
    end

    describe "#client" do
      before do
        allow(::GNTP).to receive(:new) { gntp }
        allow(gntp).to receive(:register)
      end

      it "creates a new GNTP client and memoize it" do
        expect(::GNTP).to receive(:new).
          with("Notiffany", "127.0.0.1", "", 23_053).once { gntp }

        subject.notify("Welcome")
        subject.notify("Welcome")
      end

      it "calls #register on the client and memoize it" do
        expect(::GNTP).to receive(:new).
          with("Notiffany", "127.0.0.1", "", 23_053).once { gntp }

        expect(gntp).to receive(:register).once

        subject.notify("Welcome")
        subject.notify("Welcome")
      end
    end

    describe "#notify" do
      before do
        expect(::GNTP).to receive(:new).and_return(gntp)
      end

      context "with options passed at initialization" do
        let(:options) { { title: "Hello", silent: true } }

        it "uses these options by default" do
          expect(gntp).to receive(:notify).with(
            hash_including(
              sticky: false,
              name:   "success",
              title:  "Hello",
              text:   "Welcome",
              icon:   "/tmp/welcome.png"
            )
          )

          subject.notify(
            "Welcome",
            type: :success,
            image: "/tmp/welcome.png"
          )
        end

        it "overwrites object options with passed options" do
          expect(gntp).to receive(:notify).with(
            hash_including(
              sticky: false,
              name:   "success",
              title:  "Welcome",
              text:   "Welcome to Guard",
              icon:   "/tmp/welcome.png"
            )
          )

          subject.notify(
            "Welcome to Guard",
            type: :success,
            title: "Welcome",
            image: "/tmp/welcome.png"
          )
        end
      end

      context "without additional options" do
        it "shows the notification with the default options" do
          expect(gntp).to receive(:notify).with(
            hash_including(
              sticky: false,
              name:   "success",
              title:  "Welcome",
              text:   "Welcome to Guard",
              icon:   "/tmp/welcome.png"
            )
          )

          subject.notify(
            "Welcome to Guard",
            type: :success,
            title: "Welcome",
            image: "/tmp/welcome.png"
          )
        end
      end

      context "with additional options" do
        it "can override the default options" do
          expect(gntp).to receive(:notify).with(
            hash_including(
              sticky: true,
              name:   "pending",
              title:  "Waiting",
              text:   "Waiting for something",
              icon:   "/tmp/wait.png"
            )
          )

          subject.notify(
            "Waiting for something",
            type: :pending,
            title: "Waiting",
            image: "/tmp/wait.png",
            sticky: true
          )
        end
      end
    end
  end
end
