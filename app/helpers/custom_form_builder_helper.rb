module CustomFormBuilderHelper
  class CustomFormBuilder < ActionView::Helpers::FormBuilder
    def select_custom(method, choices = nil, html_options = {},options = {}, &block)
      @template.select(@object_name, method, choices, objectify_options(options), @default_html_options.merge(html_options), &block)
    end
  end
end
