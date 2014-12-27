require "notiffany/notifier/rb_notifu"

module Notiffany
  class Notifier
    RSpec.describe Notifu do
      let(:ui) { double("ui") }
      let(:options) { { title: "Hello" } }
      let(:os) { "solaris" }
      subject { described_class.new(ui, options) }

      before do
        allow(Kernel).to receive(:require)
        allow(RbConfig::CONFIG).to receive(:[]).with("host_os") { os }

        stub_const "Notifu", double
      end

      describe "#initialize" do
        context "host is not supported" do
          let(:os) { "darwin" }

          it "fails" do
            expect { subject }.to raise_error(Base::UnsupportedPlatform)
          end
        end

        context "host is supported" do
          let(:os) { "mswin" }

          it "requires rb-notifu" do
            expect(Kernel).to receive(:require).with("rb-notifu")
            subject
          end
        end
      end

      describe "#notify" do
        let(:os) { "mswin" }

        context "with options passed at initialization" do
          it "uses these options by default" do
            expect(::Notifu).to receive(:show).with(
              time:    3,
              icon:    false,
              baloon:  false,
              nosound: false,
              noquiet: false,
              xp:      false,
              title:   "Hello",
              type:    :info,
              image:   "/tmp/welcome.png",
              message: "Welcome to Guard"
            )

            subject.notify("Welcome to Guard", image: "/tmp/welcome.png")
          end

          it "overwrites object options with passed options" do
            expect(::Notifu).to receive(:show).with(
              hash_including(
                time:    3,
                icon:    false,
                baloon:  false,
                nosound: false,
                noquiet: false,
                xp:      false,
                title:   "Welcome",
                type:    :info,
                image:   "/tmp/welcome.png",
                message: "Welcome to Guard"
              )
            )

            subject.notify("Welcome to Guard",
                           title: "Welcome",
                           image: "/tmp/welcome.png")
          end
        end

        context "without additional options" do
          it "shows the notification with the default options" do
            expect(::Notifu).to receive(:show).with(
              time:    3,
              icon:    false,
              baloon:  false,
              nosound: false,
              noquiet: false,
              xp:      false,
              title:   "Welcome",
              type:    :info,
              image:   "/tmp/welcome.png",
              message: "Welcome to Guard"
            )

            subject.notify("Welcome to Guard",
                           title: "Welcome",
                           image: "/tmp/welcome.png")
          end
        end

        context "with additional options" do
          it "can override the default options" do
            expect(::Notifu).to receive(:show).with(
              time:    5,
              icon:    true,
              baloon:  true,
              nosound: true,
              noquiet: true,
              xp:      true,
              title:   "Waiting",
              type:    :warn,
              image:   "/tmp/wait.png",
              message: "Waiting for something"
            )

            subject.notify("Waiting for something",
                           time:    5,
                           icon:    true,
                           baloon:  true,
                           nosound: true,
                           noquiet: true,
                           xp:      true,
                           title:   "Waiting",
                           type:    :pending,
                           image:   "/tmp/wait.png"
                          )
          end
        end
      end

    end
  end
end
