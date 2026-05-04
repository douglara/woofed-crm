ActionView::Base.field_error_proc = proc do |html_tag, _instance|
  if html_tag =~ /^<input|^<textarea|^<select/
    html = Nokogiri::HTML::DocumentFragment.parse(html_tag)
    element = html.at_css('input,textarea,select')
    element['class'] = "#{element['class']} form-input-error"
    html.to_html.html_safe
  else
    html_tag
  end
end
