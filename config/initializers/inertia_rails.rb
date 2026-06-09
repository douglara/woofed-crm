# frozen_string_literal: true

InertiaRails.configure do |config|
  config.version = ViteRuby.digest
  # Mount on a dedicated id so the React app never collides with the `internal`
  # layout's outer `<div id="app">` shell (which wraps the ERB sidebar/navbar).
  config.root_dom_id = 'inertia-app'
  config.encrypt_history = true
  config.always_include_errors_hash = true
  config.use_script_element_for_initial_page = true
  config.use_data_inertia_head_attribute = true
end
