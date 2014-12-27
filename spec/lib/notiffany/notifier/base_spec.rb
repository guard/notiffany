require "notiffany/notifier/base"

# TODO: no point in testing the base class, really
module Notiffany
  RSpec.describe Notifier::Base do
    let(:fake) { double ("fake_lib") }
    let(:options) { {} }
    let(:os) { "solaris" }

    subject { Notifier::FooBar.new({ fake: fake }.merge(options)) }

    before do
      allow(Kernel).to receive(:require)
      allow(RbConfig::CONFIG).to receive(:[]).with("host_os") { os }
    end

    class Notifier
      class FooBar < Notifier::Base
        DEFAULTS = { foo: :bar }

        private

        def _supported_hosts
          %w(freebsd solaris)
        end

        def _perform_notify(message, options)
          options[:fake].notify(message, options)
        end

        def _check_available(_options)
          true
        end
      end
    end

    describe "#initialize" do
      context "on unsupported os" do
        let(:os) { "mswin" }
        it "fails" do
          expect { subject }.to raise_error(Notifier::Base::UnsupportedPlatform)
        end
      end

      context "on supported os" do
        let(:os) { "freebsd" }

        context "library loads normally" do
          it "returns true" do
            expect(Kernel).to receive(:require).with("foo_bar")
            expect { subject }.to_not raise_error
          end
        end

        context "when library fails to load" do
          before do
            allow(Kernel).to receive(:require).with("foo_bar").
              and_raise LoadError
          end

          it "fails with error" do
            expect { subject }.
              to raise_error(Notifier::Base::RequireFailed)
          end
        end
      end
    end

    describe "#name" do
      it 'un-modulizes the class, replaces "xY" with "x_Y" and downcase' do
        expect(subject.name).to eq "foo_bar"
      end
    end

    describe "#title" do
      it "un-modulize the class" do
        expect(subject.title).to eq "FooBar"
      end
    end

    describe "#notify" do
      let(:opts) { {} }

      context "with no notify title overrides" do
        it "supplies default title" do
          expect(fake).to receive(:notify).
            with("foo", hash_including(title: "Notiffany"))
          subject.notify("foo", opts)
        end
      end

      context "with notify title override" do
        let(:opts) { { title: "Hi" } }
        it "uses given title" do
          expect(fake).to receive(:notify).
            with("foo", hash_including(title: "Hi"))
          subject.notify("foo", opts)
        end
      end

      context "with no type overrides" do
        it "supplies default type" do
          expect(fake).to receive(:notify).
            with("foo", hash_including(type: :success))
          subject.notify("foo", opts)
        end
      end

      context "with type given" do
        let(:opts) { { type: :foo } }
        it "uses given type" do
          expect(fake).to receive(:notify).
            with("foo", hash_including(type: :foo))
          subject.notify("foo", opts)
        end
      end

      context "with no image overrides" do
        it "supplies default image" do
          expect(fake).to receive(:notify).
            with("foo", hash_including(image: /success.png$/))
          subject.notify("foo", opts)
        end
      end

      %w(failed pending success guard).each do |img|
        context "with #{img.to_sym.inspect} image" do
          let(:opts) { { image: img.to_sym } }
          it "converts to image path" do
            expect(fake).to receive(:notify).
              with("foo", hash_including(image: /#{img}.png$/))
            subject.notify("foo", opts)
          end
        end
      end

      context "with a custom image" do
        let(:opts) { { image: "foo.jpg" } }
        it "uses given image" do
          expect(fake).to receive(:notify).
            with("foo", hash_including(image: "foo.jpg"))
          subject.notify("foo", opts)
        end
      end

      context "with nil image" do
        let(:opts) { { image: nil } }
        it "set the notify image to nil" do
          expect(fake).to receive(:notify).
            with("foo", hash_including(image: nil))
          subject.notify("foo", opts)
        end

        it "uses the default type" do
          expect(fake).to receive(:notify).
            with("foo", hash_including(type: :notify))
          subject.notify("foo", opts)
        end
      end
    end
  end
end
