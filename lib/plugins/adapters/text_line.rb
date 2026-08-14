# frozen_string_literal: true

module Plugins
  module Adapters
    # Line-based adapter for .rb, .erb, .css and any other text files.
    module TextLine
      class << self
        def apply(content, operations)
          lines = content.lines.map(&:chomp)

          operations.each do |op|
            lines = apply_operation(lines, op)
          end

          lines.join("\n") + "\n"
        end

        private

        def apply_operation(lines, op)
          case op.type
          when :after_line    then apply_after_line(lines, op)
          when :before_line   then apply_before_line(lines, op)
          when :replace_line  then apply_replace_line(lines, op)
          when :replace_block then apply_replace_block(lines, op)
          when :append_to_file  then apply_append(lines, op)
          when :prepend_to_file then apply_prepend(lines, op)
          else
            raise Plugins::FilePatch::PatchError, "Unknown operation: #{op.type}"
          end
        end

        def find_line_index(lines, containing)
          idx = lines.index { |l| l.include?(containing) }
          unless idx
            raise Plugins::FilePatch::PatchError,
                  "Line containing #{containing.inspect} not found"
          end
          idx
        end

        def apply_after_line(lines, op)
          idx = find_line_index(lines, op.options[:containing])
          new_content = normalize_block(op.block.call)
          lines.insert(idx + 1, *new_content)
          lines
        end

        def apply_before_line(lines, op)
          idx = find_line_index(lines, op.options[:containing])
          new_content = normalize_block(op.block.call)
          lines.insert(idx, *new_content)
          lines
        end

        def apply_replace_line(lines, op)
          idx = find_line_index(lines, op.options[:containing])
          lines[idx] = op.options[:with]
          lines
        end

        def apply_replace_block(lines, op)
          start_idx = find_line_index(lines, op.options[:from])
          end_idx = lines.index { |l| l.include?(op.options[:to]) }
          unless end_idx
            raise Plugins::FilePatch::PatchError,
                  "End marker #{op.options[:to].inspect} not found"
          end

          new_content = normalize_block(op.block.call)
          lines[start_idx..end_idx] = new_content
          lines
        end

        def apply_append(lines, op)
          new_content = normalize_block(op.block.call)
          lines.concat(new_content)
          lines
        end

        def apply_prepend(lines, op)
          new_content = normalize_block(op.block.call)
          lines.unshift(*new_content)
          lines
        end

        def normalize_block(result)
          text = result.to_s
          text = text.chomp
          text.split("\n", -1)
        end
      end
    end
  end
end
