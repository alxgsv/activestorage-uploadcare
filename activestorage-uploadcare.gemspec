$:.push File.expand_path('lib', __dir__)

# Maintain your gem's version:
require 'active_storage/uploadcare/version'

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.platform    = Gem::Platform::RUBY
  s.name        = 'activestorage-uploadcare'
  s.version     = ActiveStorage::Uploadcare::VERSION
  s.author      = ['Alex Gusev']
  s.email       = ['alx.gsv@gmail.com']
  s.homepage    = 'https://github.com/alxgsv/activestorage-uploadcare'
  s.summary     = 'Uploadcare Service for ActiveStorage'
  s.description = 'Allows to use Uploadcare as a storage for ActiveStorage'

  s.required_ruby_version     = '>= 2.7'
  s.required_rubygems_version = '>= 1.8.11'

  s.files = Dir['{app,config,db,lib}/**/*', 'MIT-LICENSE', 'Rakefile', 'README.md']

  s.add_dependency 'rails', '>= 5.2.2'
  s.add_dependency 'uploadcare-ruby', '< 5'

  s.add_development_dependency 'appraisal'
  s.add_development_dependency 'byebug'
  s.add_development_dependency 'sqlite3'
end
