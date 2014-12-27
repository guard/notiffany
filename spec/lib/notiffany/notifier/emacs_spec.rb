require "notiffany/notifier/emacs"

module Notiffany
  RSpec.describe Notifier::Emacs do
    let(:ui) { double("ui") }
    let(:options) { {} }
    let(:result) { fail "set me first" }
    subject { described_class.new(ui, options) }

    let(:sheller) { Shellany::Sheller }

    before do
      allow(sheller).to receive(:stdout).and_return(result)
    end

    describe "#initialize" do
      let(:cmd) { "emacsclient --eval '1' 2> #{IO::NULL} || echo 'N/A'" }

      before { allow(sheller).to receive(:stdout).with(cmd).and_return(result) }

      context "when the client command works" do
        let(:result) { "" }
        it "works" do
          subject
        end
      end

      context "when the client commmand does not exist" do
        let(:result) { nil }
        it "fails" do
          expect { subject }.to raise_error(Notifier::Base::UnavailableError)
        end
      end

      context "when the client command produces unexpected output" do
        let(:result) { "N/A" }
        it "fails" do
          expect { subject }.to raise_error(Notifier::Base::UnavailableError)
        end
      end
    end

    describe ".notify" do
      let(:result) { "" }
      context "with options passed at initialization" do
        let(:options) { { success: "Green", silent: true } }

        it "uses these options by default" do
          expect(sheller).to receive(:run) do |command, *arguments|
            expect(command).to include("emacsclient")
            expect(arguments).to include(
              "(set-face-attribute 'mode-line nil"\
              " :background \"Green\" :foreground \"White\")"
            )
          end

          subject.notify("any message")
        end

        it "overwrites object options with passed options" do
          expect(sheller).to receive(:run) do |command, *arguments|
            expect(command).to include("emacsclient")
            expect(arguments).to include(
              "(set-face-attribute 'mode-line nil"\
              " :background \"LightGreen\" :foreground \"White\")"
            )
          end

          subject.notify("any message", success: "LightGreen")
        end
      end

      context "when no color options are specified" do
        it "should set modeline color to the default color using emacsclient" do
          expect(sheller).to receive(:run) do |command, *arguments|
            expect(command).to include("emacsclient")
            expect(arguments).to include(
              "(set-face-attribute 'mode-line nil"\
              " :background \"ForestGreen\" :foreground \"White\")"
            )
          end

          subject.notify("any message")
        end
      end

      context 'when a color option is specified for "success" notifications' do
        it "sets modeline color using emacsclient" do
          expect(sheller).to receive(:run) do |command, *arguments|
            expect(command).to include("emacsclient")
            expect(arguments).to include(
              "(set-face-attribute 'mode-line nil"\
              " :background \"Orange\" :foreground \"White\")"
            )
          end

          subject.notify("any message", success: "Orange")
        end
      end

      context 'when a color option is specified for "pending" notifications' do
        it "sets modeline color using emacsclient" do
          expect(sheller).to receive(:run) do |command, *arguments|
            expect(command).to include("emacsclient")
            expect(arguments).to include(
              "(set-face-attribute 'mode-line nil"\
              " :background \"Yellow\" :foreground \"White\")"
            )
          end

          subject.notify("any message", type: :pending, pending: "Yellow")
        end
      end
    end
  end
end
