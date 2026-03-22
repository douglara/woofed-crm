# frozen_string_literal: true

module FormHelper
  SUBMIT_BUTTON_DEFAULTS = {
    variant: 'fill',
    color: 'primary',
    size: 'sm'
  }.freeze

  SPINNER_SIZES = {
    'sm' => 'w-4 h-4',
    'md' => 'w-5 h-5'
  }.freeze

  def submit_button(form, text = nil, **options)
    btn_class = build_submit_button_class(options)
    size = options.delete(:size) || SUBMIT_BUTTON_DEFAULTS[:size]
    btn_text = text || form.send(:submit_default_value)
    loading = submit_loading_html(size, btn_text)
    data = { turbo_submits_with: loading, disable_with: loading }
    data.merge!(options.delete(:data)) if options[:data]

    form.button(btn_text, class: btn_class, data:, **options)
  end

  private

  def build_submit_button_class(options)
    variant = options.delete(:variant) || SUBMIT_BUTTON_DEFAULTS[:variant]
    color = options.delete(:color) || SUBMIT_BUTTON_DEFAULTS[:color]
    size = options[:size] || SUBMIT_BUTTON_DEFAULTS[:size]
    extra_class = options.delete(:class)

    cls = "button-default-#{variant}-#{color}-#{size}"
    cls = "#{cls} #{extra_class}" if extra_class.present?
    cls
  end

  def submit_loading_html(size, btn_text)
    spinner_size = SPINNER_SIZES.fetch(size, SPINNER_SIZES['sm'])

    tag.span(
      class: 'relative inline-flex items-center cursor-wait',
      data: { controller: 'load-lucid-icons' }
    ) do
      safe_join([
                  tag.span(btn_text, class: 'invisible'),
                  submit_loading_overlay(spinner_size)
                ])
    end
  end

  def submit_loading_overlay(spinner_size)
    tag.span(class: 'absolute inset-0 flex items-center justify-center') do
      tag.i(data: { lucide: 'loader-circle' }, class: "#{spinner_size} animate-spin")
    end
  end
end
