# frozen_string_literal: true

module Plugins
  # DSL + registry + engine for file patching.
  #
  # Usage (inside a plugin patch file):
  #
  #   Plugins::FilePatch.define target: "app/models/contact.rb" do
  #     after_line containing: "class Contact" do
  #       "  include MyExtension"
  #     end
  #   end
  #
  class FilePatch
    class PatchError < StandardError; end

    Operation = Struct.new(:type, :options, :block, keyword_init: true)

    class << self
      # Global registry: target => [{ patch:, priority: }]
      def registry
        @registry ||= Hash.new { |h, k| h[k] = [] }
      end

      def define(target:, priority: 0, &block)
        patch = new(target: target, priority: priority)
        patch.instance_eval(&block)
        registry[target] << { patch: patch, priority: priority }
        patch
      end

      def patches_for(target)
        registry[target]
          .sort_by { |entry| entry[:priority] }
          .map { |entry| entry[:patch] }
      end

      def clear_registry!
        @registry = nil
      end

      # Apply all registered patches for a target to the original content.
      def apply(target, original_content)
        patches = patches_for(target)
        return original_content if patches.empty?

        content = original_content.dup
        patches.each do |patch|
          content = patch.apply_to(content)
        end
        content
      end
    end

    attr_reader :target, :priority, :operations

    def initialize(target:, priority: 0)
      @target = target
      @priority = priority
      @operations = []
    end

    # --- DSL methods ---

    def after_line(containing:, &block)
      @operations << Operation.new(type: :after_line, options: { containing: containing }, block: block)
    end

    def before_line(containing:, &block)
      @operations << Operation.new(type: :before_line, options: { containing: containing }, block: block)
    end

    def replace_line(containing:, with:)
      @operations << Operation.new(type: :replace_line, options: { containing: containing, with: with }, block: nil)
    end

    def replace_block(from:, to:, &block)
      @operations << Operation.new(type: :replace_block, options: { from: from, to: to }, block: block)
    end

    def append_to_file(&block)
      @operations << Operation.new(type: :append_to_file, options: {}, block: block)
    end

    def prepend_to_file(&block)
      @operations << Operation.new(type: :prepend_to_file, options: {}, block: block)
    end

    # --- Engine ---

    def apply_to(content)
      adapter = Plugins::Adapters.adapter_for(@target)
      adapter.apply(content, @operations)
    end
  end
end
