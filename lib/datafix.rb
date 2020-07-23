require "datafixes"
require "datafix/version"
require "datafix/railtie" if defined?(Rails)
require "datafix/datadog"

class Datafix
  extend Reporting::Datadog

  class << self
    DIRECTIONS = %w[up down]

    def disable_wrapping_transaction!
      @with_wrapping_transaction = false
    end

    def migrate(direction)
      raise ArgumentError unless DIRECTIONS.include?(direction)

      dd_event_migration_start(datafix_name: name)
      if with_wrapping_transaction?
        ActiveRecord::Base.transaction { run(direction) }
      else
        run(direction)
      end
      dd_event_migration_finished(datafix_name: name)
    end

    private

    def run(direction)
      send(direction.to_sym)
      log_run(direction)
    end

    def with_wrapping_transaction?
      @with_wrapping_transaction = true if @with_wrapping_transaction.nil?
      @with_wrapping_transaction
    end

    def log_run(direction)
      name = self.name.camelize.split('::').tap(&:shift).join('::')
      puts "migrating #{name} #{direction}"

      execute(<<-SQL)
      INSERT INTO datafix_log
      (direction, script, timestamp)
      VALUES ('#{direction}', '#{name.camelize}', NOW())
      SQL
    end

    def connection
      @connection ||= ActiveRecord::Base.connection
    end

    def execute(*args)
      connection.execute(*args)
    end

    def table_exists?(table_name)
      ActiveRecord::Base.connection.table_exists? table_name
    end

    def archive_table(table_name)
      log "Archive #{table_name} for Rollback" if self.respond_to?(:log)
      execute "CREATE TABLE archived_#{table_name} ( LIKE #{table_name} INCLUDING DEFAULTS INCLUDING CONSTRAINTS INCLUDING INDEXES )"
      execute "INSERT INTO archived_#{table_name} SELECT * FROM #{table_name}"
    end

    def revert_archive_table(table_name)
      log "Move old #{table_name} back" if self.respond_to?(:log)
      execute "TRUNCATE TABLE #{table_name}"
      execute "INSERT INTO #{table_name} SELECT * FROM archived_#{table_name}"
      execute "DROP TABLE archived_#{table_name}"
    end
  end
end
