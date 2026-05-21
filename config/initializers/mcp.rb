# frozen_string_literal: true

# Sentinel value used in update tools to distinguish "param was sent with nil"
# from "param was not sent at all" — enables PATCH semantics in tool updates.
MCP::EmptyProperty = Class.new

# Pre-load every tool/resource on boot so `ApplicationTool.descendants` and
# `ApplicationResource.descendants` are populated when McpController#mcp_server
# builds the per-request server. Without this, Zeitwerk lazy-loads classes and
# the server starts with an empty registry.
Rails.application.config.to_prepare do
  Dir[Rails.root.join('app/tools/**/*.rb')].each do |file|
    require_dependency file
  end

  Dir[Rails.root.join('app/resources/**/*.rb')].each do |file|
    require_dependency file
  end
end
