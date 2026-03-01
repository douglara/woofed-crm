# frozen_string_literal: true

namespace :plugins do
  desc 'Create a new plugin with the standard directory structure. Usage: rake plugins:create plugin_name'
  task :create do
    # Capture the argument after 'plugins:create'
    plugin_name = ARGV[1]

    if plugin_name.nil? || plugin_name.strip.empty?
      puts 'Usage: rake plugins:create plugin_name'
      puts 'Example: rake plugins:create my_plugin'
      exit 1
    end

    plugins_dir = File.expand_path('../../plugins', __dir__)
    plugin_path = File.join(plugins_dir, plugin_name)
    module_name = plugin_name.split('_').map(&:capitalize).join

    if Dir.exist?(plugin_path)
      puts "Error: Plugin '#{plugin_name}' already exists at #{plugin_path}"
      exit 1
    end

    # Create plugin using Rails engine generator
    puts "Creating plugin '#{plugin_name}'..."
    system("rails plugin new #{plugin_path} --full --skip-gemfile-entry")

    # Clean up gemspec: remove TODO placeholders that break Bundler validation
    gemspec_path = File.join(plugin_path, "#{plugin_name}.gemspec")
    if File.exist?(gemspec_path)
      content = File.read(gemspec_path)

      # Remove homepage with TODO value
      content.gsub!(/^\s*spec\.homepage\s*=\s*"TODO"\n/, '')

      # Remove all metadata lines with TODO values
      content.gsub!(/^\s*spec\.metadata\[.*\].*TODO.*\n/, '')

      # Remove metadata homepage_uri that references the removed spec.homepage
      content.gsub!(/^\s*spec\.metadata\["homepage_uri"\].*\n/, '')

      # Remove orphaned comments about push host
      content.gsub!(/^\s*# Prevent pushing this gem.*\n/, '')
      content.gsub!(/^\s*# to allow pushing to a single host.*\n/, '')

      # Replace TODO in summary and description with clean values
      content.gsub!(/TODO: Summary of (\w+)\./, 'Summary of \1.')
      content.gsub!(/TODO: Description of (\w+)\./, 'Description of \1.')

      # Clean up excessive blank lines left after removals
      content.gsub!(/\n{3,}/, "\n\n")

      File.write(gemspec_path, content)
      puts 'Gemspec cleaned up (removed TODO placeholders).'
    end

    # Install plugin dependencies
    puts 'Running bundle install...'
    system('bundle install')

    puts ''
    puts "Plugin '#{plugin_name}' created successfully!"
    puts ''
    puts 'Next steps:'
    puts '  1. Create a patch file, e.g.:'
    puts "     plugins/#{plugin_name}/app/models/patch_contact.rb"
    puts ''
    puts '  2. Define your module with the plugin namespace:'
    puts "     module #{module_name}"
    puts '       module PatchContact'
    puts '         extend ActiveSupport::Concern'
    puts '         # ...'
    puts '       end'
    puts '     end'
    puts ''
    puts '  3. Restart Rails'

    # Prevent Rake from trying to run the plugin name as another task
    exit 0
  end
end
