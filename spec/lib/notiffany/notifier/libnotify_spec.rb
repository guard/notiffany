require "notiffany/notifier/libnotify"

module Notiffany
  RSpec.describe Notifier::Libnotify do
    let(:ui) { double("ui") }
    let(:options) { {} }
    let(:os) { "solaris" }
    subject { described_class.new(ui, options) }

    before do
      stub_const "Libnotify", double

      allow(Kernel).to receive(:require)
      allow(RbConfig::CONFIG).to receive(:[]).with("host_os") { os }
    end

    describe "#initialize" do
      let(:os) { "mswin" }
      context "with unsupported host" do
        it "does not require libnotify" do
          expect(Kernel).to_not receive(:require)
          expect { subject }.to raise_error(Notifier::Base::UnsupportedPlatform)
        end
      end

      context "host is supported" do
        let(:os) { "linux" }
        it "requires libnotify" do
          expect(Kernel).to receive(:require).and_return(true)
          subject
        end
      end
    end

    describe "#notify" do
      context "with options passed at initialization" do
        let(:options) { { title: "Hello", silent: true } }

        it "uses these options by default" do
          expect(::Libnotify).to receive(:show).with(
            hash_including(
              transient: false,
              append:    true,
              timeout:   3,
              urgency:   :low,
              summary:   "Hello",
              body:      "Welcome to Guard",
              icon_path: "/tmp/welcome.png"
            )
          )

          subject.notify("Welcome to Guard", image: "/tmp/welcome.png")
        end

        it "overwrites object options with passed options" do
          expect(::Libnotify).to receive(:show).with(
            hash_including(
              transient: false,
              append:    true,
              timeout:   3,
              urgency:   :low,
              summary:   "Welcome",
              body:      "Welcome to Guard",
              icon_path: "/tmp/welcome.png"
            )
          )

          subject.notify("Welcome to Guard",
                         title: "Welcome",
                         image: "/tmp/welcome.png")
        end
      end

      context "without additional options" do
        it "shows the notification with the default options" do
          expect(::Libnotify).to receive(:show).with(
            hash_including(
              transient: false,
              append:    true,
              timeout:   3,
              urgency:   :low,
              summary:   "Welcome",
              body:      "Welcome to Guard",
              icon_path: "/tmp/welcome.png"
            )
          )

          subject.notify("Welcome to Guard",
                         title: "Welcome",
                         image: "/tmp/welcome.png")
        end
      end

      context "with additional options" do
        it "can override the default options" do
          expect(::Libnotify).to receive(:show).with(
            hash_including(
              transient: true,
              append:    false,
              timeout:   5,
              urgency:   :critical,
              summary:   "Waiting",
              body:      "Waiting for something",
              icon_path: "/tmp/wait.png"
            )
          )

          subject.notify("Waiting for something",
                         type: :pending,
                         title: "Waiting",
                         image: "/tmp/wait.png",
                         transient: true,
                         append:    false,
                         timeout:   5,
                         urgency:   :critical
                        )
        end
      end
    end
  end
end
