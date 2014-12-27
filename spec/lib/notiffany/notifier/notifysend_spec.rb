require "notiffany/notifier/notifysend"

module Notiffany
  class Notifier
    RSpec.describe NotifySend do
      let(:options) { {} }
      let(:os) { "solaris" }
      subject { described_class.new(options) }

      let(:sheller) { class_double("Shellany::Sheller") }

      before do
        allow(Kernel).to receive(:require)
        allow(RbConfig::CONFIG).to receive(:[]).with("host_os") { os }

        stub_const "NotifySend", double
        stub_const("Shellany::Sheller", sheller)

        allow(sheller).to receive(:stdout)
      end

      describe "#initialize" do
        context "host is not supported" do
          let(:os) { "mswin" }

          it "do not check if the binary is available" do
            expect(sheller).to_not receive(:stdout)
            expect { subject }.to raise_error(Base::UnsupportedPlatform)
          end
        end

        context "host is supported" do
          let(:os) { "linux" }

          it "checks if the binary is available" do
            expect(sheller).to receive(:stdout).with("which notify-send").
                                       and_return("foo\n")
            subject
          end
        end
      end

      describe "#notify" do
        before do
          allow(sheller).to receive(:stdout).with("which notify-send").
            and_return("foo\n")
        end

        context "with options passed at initialization" do
          let(:options) { { image: "/tmp/hello.png", silent: true } }

          it "uses these options by default" do
            expect(sheller).to receive(:run) do |command, *arguments|
              expect(command).to eql "notify-send"
              expect(arguments).to include "-i", "/tmp/hello.png"
              expect(arguments).to include "-u", "low"
              expect(arguments).to include "-t", "3000"
              expect(arguments).to include "-h", "int:transient:1"
            end

            subject.notify("Welcome")
          end

          it "overwrites object options with passed options" do
            expect(sheller).to receive(:run) do |command, *arguments|
              expect(command).to eql "notify-send"
              expect(arguments).to include "-i", "/tmp/welcome.png"
              expect(arguments).to include "-u", "low"
              expect(arguments).to include "-t", "3000"
              expect(arguments).to include "-h", "int:transient:1"
            end

            subject.notify("Welcome", image: "/tmp/welcome.png")
          end

          it "uses the title provided in the options" do
            expect(sheller).to receive(:run) do |command, *arguments|
              expect(command).to eql "notify-send"
              expect(arguments).to include "Welcome"
              expect(arguments).to include "test title"
            end
            subject.notify("Welcome", title: "test title")
          end

          it "converts notification type failed to normal urgency" do
            expect(sheller).to receive(:run) do |command, *arguments|
              expect(command).to eql "notify-send"
              expect(arguments).to include "-u", "normal"
            end

            subject.notify("Welcome", type: :failed)
          end

          it "converts notification type pending to low urgency" do
            expect(sheller).to receive(:run) do |command, *arguments|
              expect(command).to eql "notify-send"
              expect(arguments).to include "-u", "low"
            end

            subject.notify("Welcome", type: :pending)
          end
        end

        context "without additional options" do
          it "shows the notification with the default options" do
            expect(sheller).to receive(:run) do |command, *arguments|
              expect(command).to eql "notify-send"
              expect(arguments).to include "-i", "/tmp/welcome.png"
              expect(arguments).to include "-u", "low"
              expect(arguments).to include "-t", "3000"
              expect(arguments).to include "-h", "int:transient:1"
            end

            subject.notify("Welcome", image: "/tmp/welcome.png")
          end
        end

        context "with additional options" do
          it "can override the default options" do
            expect(sheller).to receive(:run) do |command, *arguments|
              expect(command).to eql "notify-send"
              expect(arguments).to include "-i", "/tmp/wait.png"
              expect(arguments).to include "-u", "critical"
              expect(arguments).to include "-t", "5"
            end

            subject.notify(
              "Waiting for something",
              type: :pending,
              image: "/tmp/wait.png",
              t: 5,
              u: :critical
            )
          end
        end
      end
    end
  end
end
