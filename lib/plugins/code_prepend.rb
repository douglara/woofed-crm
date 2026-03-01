# frozen_string_literal: true

require 'pathname'

module Plugins
  # CodePrepend - Automatic module prepending system for WoofedCRM plugins
  #
  # Allows plugins to extend main application classes by defining modules
  # with the 'patch_' prefix. When the target class is loaded by Zeitwerk,
  # the corresponding Patch* module is automatically prepended.
  #
  # Each plugin's patch module is namespaced under the plugin name to avoid
  # conflicts when multiple plugins patch the same class.
  #
  # ## Directory Structure
  #
  # Patch modules use the prefix 'patch_' in the same directory:
  #
  #   plugins/example/app/models/patch_contact.rb -> Example::PatchContact prepended to Contact
  #   plugins/example/app/models/patch_deal.rb -> Example::PatchDeal prepended to Deal
  #   plugins/example/app/controllers/accounts/patch_contacts_controller.rb
  #     -> Example::Accounts::PatchContactsController prepended to Accounts::ContactsController
  #
  # ## Example Patch Module
  #
  #   # plugins/example/app/models/patch_contact.rb
  #   module Example
  #     module PatchContact
  #       extend ActiveSupport::Concern
  #
  #       prepended do
  #         has_many :custom_things
  #       end
  #
  #       def custom_method
  #         'hello'
  #       end
  #     end
  #   end
  #
  module CodePrepend
    attr_reader :extensions

    def setup_code_prepend!
      @extensions = {}

      plugins.each do |plugin_dir|
        scan_prepend_files(plugin_dir)
      end
    end

    def has_extension_for?(class_name)
      @extensions&.key?(class_name)
    end

    def apply_extensions(class_name, klass)
      return unless @extensions&.key?(class_name)

      @extensions[class_name].each do |extension|
        klass.prepend(extension[:module])
        log_debug("Applied #{extension[:module_name]} to #{class_name}")
      end
    end

    private

    def scan_prepend_files(plugin_dir)
      app_path = plugin_dir.join('app')
      return unless app_path.exist?

      plugin_name = plugin_dir.basename.to_s

      Dir.glob(app_path.join('**/patch_*.rb')).sort.each do |file|
        register_extension(file, app_path, plugin_name)
      end
    end

    def register_extension(file, app_path, plugin_name)
      relative = Pathname.new(file).relative_path_from(app_path).to_s.sub(/\.rb$/, '')
      # Ex: "models/contacts/patch_contact_sync"

      # Remove prefixo patch_ para obter o path da classe original
      # Ex: "models/contacts/patch_contact_sync" -> "models/contacts/contact_sync"
      target_path = relative.gsub(%r{(^|/)patch_}, '\1')

      # Converte para nome de classe (removendo models/, controllers/, etc.)
      # Ex: "models/contacts/contact_sync" -> "Contacts::ContactSync"
      target_class_name = target_path.split('/')[1..].join('/').camelize

      # Namespace do plugin + nome do módulo patch
      # Ex: plugin_name = "example", relative = "models/patch_contact"
      # module_name = "Example::PatchContact"
      module_name = "#{plugin_name.camelize}::#{relative.split('/')[1..].join('/').camelize}"

      # Load the file to define the Patch* module
      load file

      mod = module_name.constantize
      return unless mod.instance_of?(Module)

      @extensions[target_class_name] ||= []
      @extensions[target_class_name] << { module: mod, module_name: module_name, file: file }

      log_debug("Registered #{module_name} for #{target_class_name}")
    rescue StandardError => e
      log_warn("Failed to register extension #{file}: #{e.message}")
    end

    def log_debug(message)
      return unless defined?(Rails) && Rails.respond_to?(:logger) && Rails.logger

      Rails.logger.debug { "Plugin CodePrepend: #{message}" }
    end

    def log_warn(message)
      return unless defined?(Rails) && Rails.respond_to?(:logger) && Rails.logger

      Rails.logger.warn("Plugin CodePrepend: #{message}")
    end
  end
end
