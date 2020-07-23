require "datadog/statsd"

module Reporting
  module Datadog
    def dd_event_migration_start(datafix_name:)
      dd_event(datafix_name: datafix_name, position: "start")
    end

    def dd_event_migration_finished(datafix_name:)
      dd_event(datafix_name: datafix_name, position: "finished")
    end

    private

    def dd_event(datafix_name:, position:)
      statsd = ::Datadog::Statsd.new
      statsd.event("Running Datafix", datafix_name, tags: ["datafix", position])
    end
  end
end
