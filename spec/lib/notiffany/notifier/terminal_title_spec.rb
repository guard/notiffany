require "notiffany/notifier/terminal_title"

RSpec.describe Notiffany::Notifier::TerminalTitle do
  let(:ui) { double("ui") }
  let(:options) { { title: "Hello" } }
  let(:os) { "solaris" }
  subject { described_class.new(ui, options) }

  before do
    allow(Kernel).to receive(:require)
    allow(RbConfig::CONFIG).to receive(:[]).with("host_os") { os }
  end

  describe "#notify" do
    context "with options passed at initialization" do
      it "uses these options by default" do
        expect(STDOUT).to receive(:puts).with("\e]2;[Hello] first line\a")
        subject.notify("first line\nsecond line\nthird")
      end

      it "overwrites object options with passed options" do
        expect(STDOUT).to receive(:puts).with("\e]2;[Welcome] first line\a")
        subject.notify("first line\nsecond line\nthird", title: "Welcome")
      end
    end

    it "set title + first line of message to terminal title" do
      expect(STDOUT).to receive(:puts).with("\e]2;[any title] first line\a")
      subject.notify("first line\nsecond line\nthird", title: "any title")
    end
  end

  describe ".turn_off" do
    it "clears the terminal title" do
      expect(STDOUT).to receive(:puts).with("\e]2;\a")
      subject.turn_off
    end
  end
end
