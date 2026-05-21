# frozen_string_literal: true

# Base class for MCP resources that respond to URI templates like
# `woofed:///deals/{id}`. The MCP SDK exposes templates only as metadata
# (MCP::ResourceTemplate) and dispatches reads via `resources_read_handler`,
# so this class fills the gap:
#
#   - holds the DSL (`uri_template`, `resource_name`, `description`,
#     `mime_type`) needed to build template metadata
#   - matches a request URI against the template, exposing placeholder
#     values as `params`
#   - delegates the actual fetch to subclasses via `#content`
#
# McpController wires this up by passing
# `resource_templates: ApplicationResource.descendants.map(&:to_resource_template)`
# to MCP::Server and routing reads back to `ApplicationResource.read`.
class ApplicationResource
  class << self
    attr_reader :uri_template_value, :resource_name_value, :description_value,
                :mime_type_value, :uri_pattern

    def uri_template(value)
      @uri_template_value = value
      pattern_source = value.gsub(/\{(\w+)\}/) { "(?<#{::Regexp.last_match(1)}>[^/]+)" }
      @uri_pattern = Regexp.new("\\A#{pattern_source}\\z")
    end

    def resource_name(value); @resource_name_value = value; end
    def description(value);   @description_value   = value; end
    def mime_type(value);     @mime_type_value     = value; end

    def to_resource_template
      MCP::ResourceTemplate.new(
        uri_template: uri_template_value,
        name:         resource_name_value,
        description:  description_value,
        mime_type:    mime_type_value
      )
    end

    def match(uri)
      return nil unless uri_pattern

      m = uri_pattern.match(uri)
      m && m.named_captures.transform_keys(&:to_sym)
    end

    # Dispatch a `resources/read` call: find the descendant whose URI template
    # matches `uri`, instantiate it, and return the MCP-shaped contents array.
    # Missing-record errors are surfaced as a text response so the LLM sees a
    # readable message instead of a generic JSON-RPC internal error.
    def read(uri, server_context: {})
      descendants.each do |klass|
        params = klass.match(uri)
        next unless params

        begin
          body = klass.new(params, server_context).content
          return [{ uri: uri, mimeType: klass.mime_type_value, text: body }]
        rescue ActiveRecord::RecordNotFound => e
          return [{ uri: uri, mimeType: 'text/plain', text: e.message }]
        end
      end

      [{ uri: uri, mimeType: 'text/plain', text: "No resource matches URI: #{uri}" }]
    end
  end

  attr_reader :params, :server_context

  def initialize(params, server_context = {})
    @params = params
    @server_context = server_context
  end

  def current_user
    server_context[:current_user]
  end

  def current_account
    server_context[:current_account]
  end

  def content
    raise NotImplementedError, 'Subclasses must implement #content'
  end
end
