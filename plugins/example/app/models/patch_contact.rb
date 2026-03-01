module Example
  module PatchContact
    extend ActiveSupport::Concern

    prepended do
      def plugin_method
        puts('Testing from Example plugin')
      end
    end
  end
end
