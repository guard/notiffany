require "notiffany/notifier/emacs"

module Notiffany
  RSpec.describe Notifier::Emacs::Client do
    let(:sheller) { Shellany::Sheller }
    subject { described_class.new({client: 'emacsclient'}) }

    before do
      allow(sheller).to receive(:run) do |*args|
        fail "stub me: #{sheller.class}(#{args.map(&:inspect) * ","})"
      end
    end

    describe "#available?" do
      before do
        allow(sheller).to receive(:run).with('emacsclient', '--eval', "'1'").
          and_return(result)
      end

      context "when the client command works" do
        let(:result) { true }
        it { is_expected.to be_available }
      end

      context "when the client commmand does not exist" do
        let(:result) { nil }
        it { is_expected.to_not be_available }
      end

      context "when the client command fails" do
        let(:result) { false }
        it { is_expected.to_not be_available }
      end
    end
  end

  RSpec.describe Notifier::Emacs do
    let(:options) { {} }
    let(:result) { fail "set me first" }
    let(:client) { instance_double(Notifier::Emacs::Client) }

    subject { described_class.new(options) }

    before do
      allow(Notifier::Emacs::Client).to receive(:new).and_return(client)
      allow(client).to receive(:available?).and_return(result)
    end

    describe "#initialize" do
      context "when the client command works" do
        let(:result) { true }
        it "works" do
          subject
        end
      end

      context "when the client command fails" do
        let(:result) { false }
        it "fails" do
          expect { subject }.to raise_error(Notifier::Base::UnavailableError)
        end
      end
    end

    describe "#notify" do
      let(:result) { "" }
      before do
        allow(client).to receive(:available?).and_return(true)
      end

      context "with options passed at initialization" do
        let(:options) { { success: "Green", silent: true } }

        it "uses these options by default" do
          expect(client).to receive(:notify).with("White", "Green")
          subject.notify("any message")
        end

        it "overwrites object options with passed options" do
          expect(client).to receive(:notify).with("White", "LightGreen")
          subject.notify("any message", success: "LightGreen")
        end
      end

      describe "modeline color" do
        context "when no color options are specified" do
          it "is set to default color" do
            expect(client).to receive(:notify).with("White", "ForestGreen")
            subject.notify("any message")
          end
        end

        context 'when a success color is specified' do
          it "is set to success color" do
            expect(client).to receive(:notify).with("White", "Orange")
            subject.notify("any message", success: "Orange")
          end
        end

        context 'when a pending color is specified for "pending" notifications' do
          it "is set to pending color" do
            expect(client).to receive(:notify).with("White", "Yellow")
            subject.notify("any message", type: :pending, pending: "Yellow")
          end
        end
      end
    end
  end
end
