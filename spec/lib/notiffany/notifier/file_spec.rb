require "notiffany/notifier/file"

module Notiffany
  RSpec.describe Notifier::File do
    let(:options) { {} }
    subject { described_class.new(options) }

    describe "#available" do
      context "with path option" do
        let(:options) { { path: ".guard_result" } }
        it "works" do
          subject
        end
      end

      context "with no path option" do
        it "fails" do
          expect { subject }.to raise_error(Notifier::Base::UnavailableError)
        end
      end
    end

    describe "#notify" do
      let(:options) { { path: "/tmp/foo" } }
      context "with options passed at initialization" do
        let(:options) { { path: "tmp/guard_result", silent: true } }

        it "uses these options by default" do
          expect(File).to receive(:write).
            with("tmp/guard_result", "success\nany title\nany message\n")

          subject.notify("any message", title: "any title")
        end

        it "overwrites object options with passed options" do
          expect(File).to receive(:write).
            with("tmp/guard_result_final", "success\nany title\nany message\n")

          subject.notify("any message",
                         title: "any title",
                         path: "tmp/guard_result_final")
        end
      end

      it "writes to a file on success" do
        expect(File).to receive(:write).
          with("tmp/guard_result", "success\nany title\nany message\n")

        subject.notify("any message",
                       title: "any title",
                       path: "tmp/guard_result")
      end

      it "also writes to a file on failure" do
        expect(File).to receive(:write).
          with("tmp/guard_result", "failed\nany title\nany message\n")

        subject.notify("any message",
                       type: :failed,
                       title: "any title",
                       path: "tmp/guard_result")
      end

      # We don't have a way to return false in .available? when no path is
      # specified. So, we just don't do anything in .notify if there's no path.
      it "does not write to a file if no path is specified" do
        expect(File).to_not receive(:write)

        expect { subject.notify("any message", path: nil) }.
          to raise_error(Notifier::Base::UnavailableError)
      end
    end
  end
end
