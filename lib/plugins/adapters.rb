# frozen_string_literal: true

module Plugins
  module Adapters
    # Picks the correct adapter based on file extension.
    def self.adapter_for(target)
      ext = File.extname(target).downcase
      case ext
      when ".js", ".jsx", ".ts", ".tsx"
        # JS/JSX/TS/TSX files use the same line-based approach — the "AST"
        # name is kept for the spec but the implementation is line-based,
        # which is sufficient for the comment-marker approach.
        Plugins::Adapters::JsAst
      else
        Plugins::Adapters::TextLine
      end
    end
  end
end
