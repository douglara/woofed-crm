# frozen_string_literal: true

namespace :plugins do
  desc "Wipe and recreate storage/build/ from scratch"
  task rebuild: :environment do
    puts "Rebuilding storage/build/..."
    manager = Plugins::BuildManager.new
    manager.rebuild!
    puts "Done. Files in storage/build/:"
    manager.status.each { |f| puts "  #{f}" }
  end

  desc "Print composed file after patches (e.g. rails plugins:preview[app/models/contact.rb])"
  task :preview, [:target] => :environment do |_t, args|
    target = args[:target]
    abort "Usage: rails plugins:preview[app/models/contact.rb]" unless target

    manager = Plugins::BuildManager.new
    result = manager.preview(target)

    if result
      puts result
    else
      abort "File not found: #{target}"
    end
  end

  desc "List all files currently in storage/build/"
  task status: :environment do
    manager = Plugins::BuildManager.new
    files = manager.status

    if files.empty?
      puts "storage/build/ is empty or does not exist."
    else
      puts "Files in storage/build/ (#{files.size}):"
      files.each { |f| puts "  #{f}" }
    end
  end
end
