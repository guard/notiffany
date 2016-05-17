require 'notiffany/notifier/emacs'
require 'notiffany/notifier/emacs/client'

RSpec.describe Notiffany::Notifier::Emacs::Client do
  let(:sheller) { Shellany::Sheller }

  let(:default_options) { { client: 'emacsclient', elisp_erb: elisp_erb } }
  let(:options) { default_options }
  subject { described_class.new(options) }

  before do
    allow(sheller).to receive(:run) do |*args|
      raise "stub me: #{sheller.class}(#{args.map(&:inspect) * ','})"
    end
  end

  describe '#initialize' do
    context 'when constructed without elisp_erb' do
      let(:elisp_erb) { nil }
      let(:options) { default_options.merge(elisp_erb: nil) }
      it 'fails with an error' do
        expect do
          subject
        end.to raise_error(ArgumentError, 'No :elisp_erb option given!')
      end
    end
  end

  describe '#available?' do
    let(:elisp_erb) { "'<%= 0+1 %>'" }

    before do
      allow(sheller).to receive(:run).with(
        { 'ALTERNATE_EDITOR' => 'false' },
        'emacsclient',
        '--eval',
        "'1'"
      ).and_return(result)
    end

    context 'with a working client command' do
      let(:result) { true }
      it { is_expected.to be_available }
    end

    context 'when the client commmand does not exist' do
      let(:result) { nil }
      it { is_expected.to_not be_available }
    end

    context 'when the client command fails' do
      let(:result) { false }
      it { is_expected.to_not be_available }
    end
  end

  # TODO: handle failure emacs failure due to elisp error?
  describe '#notify' do
    context 'when constructed with valid elisp Erb' do
      let(:elisp_erb) do
        "( print 'color is <%= color %>, bg color is <%= bgcolor %>' )"
      end

      let(:result) { true }

      it 'evaluates using given colors' do
        expect(sheller).to receive(:run).with(
          anything,
          'emacsclient',
          '--eval',
          "( print 'color is Green, bg color is Black' )"
        ).and_return(result)
        subject.notify('Green', 'Black')
      end

      context 'with a message' do
        let(:elisp_erb) { "( print 'Info: <%= message %>' )" }
        it 'evaluates using given message' do
          expect(sheller).to receive(:run).with(
            anything,
            'emacsclient',
            '--eval',
            "( print 'Info: FooBar' )"
          ).and_return(result)
          subject.notify('Green', 'Black', 'FooBar')
        end
      end
    end
  end
end
