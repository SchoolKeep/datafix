describe Datafix do
  without_wrapping_transaction  = Class.new(Datafix) do
    disable_wrapping_transaction!

    def self.name
      "Datafixes::WithoutWrappingTransaction"
    end

    def self.name_after
      @name_after
    end

    def self.up
      table_name = Kitten.table_name
      archive_table(table_name)
      execute %Q{ UPDATE #{table_name} SET name = 'garfield'; }
    end
  end

  it "can run the datafix without a wrapping transaction" do
    Kitten.create!(name: "tigger")
    allow(ActiveRecord::Base).to receive(:transaction)

    without_wrapping_transaction.migrate('up')

    expect(ActiveRecord::Base).not_to have_received(:transaction)
  end
end
