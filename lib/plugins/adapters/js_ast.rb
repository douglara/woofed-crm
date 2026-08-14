# frozen_string_literal: true

module Plugins
  module Adapters
    # Adapter for .js, .jsx, .ts, .tsx files.
    # Uses line-based matching (same strategy as TextLine) because the DSL
    # relies on string markers / comment anchors rather than AST manipulation.
    module JsAst
      class << self
        def apply(content, operations)
          # Delegate to TextLine — the DSL is identical for all text-based files.
          Plugins::Adapters::TextLine.apply(content, operations)
        end
      end
    end
  end
end
