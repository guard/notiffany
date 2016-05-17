require 'notiffany/notifier/emacs'

RSpec.describe Notiffany::Notifier::Emacs do
  let(:options) { {} }

  subject { described_class.new(options) }

  let(:availability_command_result) { true }
  let(:availability_checking_client) do
    instance_double(
      described_class::Client,
      available?: availability_command_result
    )
  end

  before do
    allow(described_class::Client).to receive(:new) do |*args|
      args_info = args.map(&:inspect) * ','
      raise "stub me: #{described_class::Client}.new(#{args_info})"
    end

    allow(described_class::Client).to receive(:new)
      .with(hash_including(elisp_erb: "'1'"))
      .and_return(availability_checking_client)
  end

  before do
    allow(File).to receive(:expand_path) do |*args|
      raise "stub me: File.expand_path(#{args.map(&:inspect) * ','})"
    end

    allow(IO).to receive(:read) do |*args|
      raise "stub me: IO.read(#{args.map(&:inspect) * ','})"
    end
  end

  describe '#initialize' do
    context 'when the client command works' do
      let(:availability_command_result) { true }
      it 'works' do
        subject
      end
    end

    context 'when the client command fails' do
      let(:availability_command_result) { false }
      it 'fails' do
        expect { subject }
          .to raise_error(Notiffany::Notifier::Base::UnavailableError)
      end
    end
  end

  describe '#notify' do
    let(:notifying_client) { instance_double(described_class::Client) }

    before do
      allow(notifying_client).to receive(:notify)
      default_elisp = { elisp_erb: described_class::DEFAULT_ELISP_ERB }
      allow(described_class::Client).to receive(:new)
        .with(hash_including(default_elisp))
        .and_return(notifying_client)
    end

    describe 'color' do
      context 'when left default' do
        context 'without overriding global options' do
          it 'is set to default' do
            expect(notifying_client).to receive(:notify)
              .with('White', 'ForestGreen', anything)
            subject.notify('any message')
          end
        end
      end

      context 'when set globally' do
        let(:options) { { success: 'Pink', silent: true } }

        context 'when no overring notification options' do
          it 'is set to global value' do
            expect(notifying_client).to receive(:notify)
              .with('White', 'Pink', anything)
            subject.notify('any message')
          end
        end
      end

      context 'when set during notification' do
        describe 'for :success' do
          let(:notification_options) { { success: 'Orange' } }
          it 'is set from the notification value' do
            expect(notifying_client).to receive(:notify)
              .with('White', 'Orange', anything)
            subject.notify('any message', notification_options)
          end
        end

        describe 'for :pending' do
          let(:notification_options) { { type: :pending, pending: 'Yellow' } }
          it 'is set from the notification value' do
            expect(notifying_client).to receive(:notify)
              .with('White', 'Yellow', anything)
            subject.notify('any message', notification_options)
          end
        end
      end
    end

    context 'with no elisp file' do
      let(:options) { {} }

      it 'uses default elisp notification code' do
        expected_elisp_erb = <<EOF
(set-face-attribute 'mode-line nil
  :background "<%= bgcolor %>"
  :foreground "<%= color %>")
EOF
        expected = { elisp_erb: expected_elisp_erb }

        expect(described_class::Client).to receive(:new)
          .with(hash_including(expected))
          .and_return(notifying_client)
        subject.notify('any message')
      end
    end

    context 'with elisp file' do
      let(:options) { { elisp_file: '~/.my_elisp_script' } }

      before do
        allow(File).to receive(:expand_path)
          .with('~/.my_elisp_script')
          .and_return('/foo/bar')

        allow(IO).to receive(:read)
          .with('/foo/bar')
          .and_return('( print "hello, color is: <%= color %>" )')
      end

      it 'passes evaluated erb to client' do
        expected = { elisp_erb: '( print "hello, color is: <%= color %>" )' }
        expect(described_class::Client).to receive(:new)
          .with(hash_including(expected))
          .and_return(notifying_client)
        subject.notify('any message')
      end
    end
  end
end
