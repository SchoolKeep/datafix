require "spec_helper"

class Datafixes::FixKittens < Datafix
  def self.up
    table_name = Kitten.table_name
    archive_table(table_name)
    execute %Q{ UPDATE #{table_name} SET fixed = 't'; }
  end

  def self.down
    table_name = Kitten.table_name
    revert_archive_table(table_name)
  end
end

describe Datafix do

  let(:kitten_names) { %w[nyan hobbes stimpy tigger garfield] }
  let(:table_name) { Kitten.table_name }
  let(:archived_table_name) { "archived_#{table_name}" }

  before do
    kitten_names.each do |name|
      Kitten.create!(name: name)
    end
    expect(Kitten.where(fixed: true)).to be_empty
  end

  context "after running fix kittens up" do
    before do
      Datafixes::FixKittens.migrate('up')
    end

    it "fixes all kittens" do
      expect(Kitten.where(fixed: false)).to be_empty
    end

    it "creates a kittens archive table" do
      expect(Kitten.connection.table_exists?(archived_table_name)).to eq true
      expect(Kitten.connection.select_value("SELECT COUNT(*) FROM #{archived_table_name}").to_i).to eq kitten_names.size
    end

    it "updates the datafix log" do
      datafix_log = DatafixLog.last
      expect(datafix_log.direction).to eq 'up'
      expect(datafix_log.script).to eq 'FixKittens'
    end

    context "after running fix kittens down" do
      before do
        Datafixes::FixKittens.migrate('down')
      end

      it "unfixes the kittens" do
        expect(Kitten.where(fixed: true)).to be_empty
      end

      it "removes the kittens archive table" do
        expect(Kitten.connection.table_exists?("archived_kittens")).to eq false
      end

      it "updates the datafix log" do
        datafix_log = DatafixLog.last
        expect(datafix_log.direction).to eq 'down'
        expect(datafix_log.script).to eq 'FixKittens'
      end
    end
  end

  context "reporting" do
    let(:statsd) { Datadog::Statsd.new }

    it "sends event to DataDog" do
      allow(::Datadog::Statsd).to receive(:new).and_return(statsd)

      expect(statsd).
        to receive(:event).
        with("Running Datafix", "Datafixes::FixKittens", { tags: %w[datafix start] })

      expect(statsd).
        to receive(:event).
        with("Running Datafix", "Datafixes::FixKittens", { tags: %w[datafix finished] })

      Datafixes::FixKittens.migrate('up')
    end
  end
end
