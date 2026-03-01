require_relative 'lib/example/version'

Gem::Specification.new do |spec|
  spec.name        = 'example'
  spec.version     = Example::VERSION
  spec.authors     = ['Write your name']
  spec.email       = [' Write your email address']
  spec.summary     = 'Summary of Example.'
  spec.description = 'Description of Example.'

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir['{app,config,db,lib}/**/*', 'MIT-LICENSE', 'Rakefile', 'README.md']
  end

  spec.add_dependency 'rails', '>= 7.1.5.1'
end
