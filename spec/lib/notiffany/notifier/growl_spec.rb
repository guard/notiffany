require "notiffany/notifier/growl"

module Notiffany
  RSpec.describe Notifier::Growl do
    module FakeGrowl
      def self.notify(_message, _opts)
      end

      def self.installed?
      end

      class Base
        def self.switches
          [:sticky, :priority, :name, :title, :image]
        end
      end
    end
    let(:growl) { FakeGrowl }

    let(:options) { {} }
    let(:os) { "solaris" }
    subject { described_class.new(options) }

    before do
      allow(Kernel).to receive(:require)
      allow(RbConfig::CONFIG).to receive(:[]).with("host_os") { os }

      stub_const "Growl", growl
      allow(growl).to receive(:installed?).and_return(true)
      allow(growl).to receive(:notify)
    end

    describe "#initialize" do
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

        context "when Growl is not installed" do
          before do
            allow(growl).to receive(:installed?).and_return(false)
          end

          it "fails" do
            expect { subject }.to raise_error(Notifier::Base::UnavailableError)
          end
        end
      end
    end

    describe "#notify" do
      let(:os) { "darwin" }
      context "with options passed at initialization" do
        let(:options) { { title: "Hello", silent: true } }

        it "uses these options by default" do
          expect(growl).to receive(:notify).with(
            "Welcome!",
            hash_including(
              sticky:   false,
              priority: 0,
              name:     "Notiffany",
              title:    "Hello",
              image:    "/tmp/welcome.png"
            )
          )

          subject.notify("Welcome!", image: "/tmp/welcome.png")
        end

        it "overwrites object options with passed options" do
          expect(growl).to receive(:notify).with(
            "Welcome!",
            hash_including(
              sticky:   false,
              priority: 0,
              name:     "Notiffany",
              title:    "Welcome",
              image:    "/tmp/welcome.png"
            )
          )

          subject.notify("Welcome!",
                         title: "Welcome",
                         image: "/tmp/welcome.png")
        end
      end

      context "without additional options" do
        it "shows the notification with the default options" do
          expect(growl).to receive(:notify).with(
            "Welcome!",
            hash_including(
              sticky:   false,
              priority: 0,
              name:     "Notiffany",
              title:    "Welcome",
              image:    "/tmp/welcome.png"
            )
          )

          subject.notify(
            "Welcome!",
            title: "Welcome",
            image: "/tmp/welcome.png")
        end
      end

      context "with additional options" do
        it "can override the default options" do
          expect(growl).to receive(:notify).with(
            "Waiting for something",
            hash_including(
              sticky:   true,
              priority: 2,
              name:     "Notiffany",
              title:    "Waiting",
              image:    "/tmp/wait.png"
            )
          )

          subject.notify(
            "Waiting for something",
            type: :pending,
            title: "Waiting",
            image: "/tmp/wait.png",
            sticky:   true,
            priority: 2
          )
        end
      end

      context "with options Growl cannot handle" do
        it "passes options only Growl can handle" do
          expect(growl).to receive(:notify).with(
            "Foo",
            sticky:   true,
            priority: 2,
            name:     "Notiffany",
            title:    "Waiting",
            image:    "/tmp/wait.png"
          )

          subject.notify(
            "Foo",
            foo: :bar,
            type: :pending,
            title: "Waiting",
            image: "/tmp/wait.png",
            sticky:   true,
            priority: 2
          )
        end
      end
    end
  end
end
