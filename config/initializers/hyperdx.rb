if ENV['OTEL_EXPORTER_OTLP_HEADERS'].present?
  require 'opentelemetry-exporter-otlp'
  require 'opentelemetry/instrumentation/all'
  require 'opentelemetry/sdk'

  OpenTelemetry::SDK.configure do |c|
    c.use_all() # enables all trace instrumentation!
  end

  Rails.application.configure do
    Rails.logger = Logger.new(STDOUT)
    Rails.logger.formatter = proc do |severity, time, progname, msg|
      span_id = OpenTelemetry::Trace.current_span.context.hex_span_id
      trace_id = OpenTelemetry::Trace.current_span.context.hex_trace_id
      if defined? OpenTelemetry::Trace.current_span.name
        operation = OpenTelemetry::Trace.current_span.name
      else
        operation = 'undefined'
      end
  
      { "time" => time, "level" => severity, "message" => msg, "trace_id" => trace_id, "span_id" => span_id,
        "operation" => operation }.to_json + "\n"
    end
  
    Rails.logger.info "Logger initialized !! 🐱"
  end
end