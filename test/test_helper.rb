# Configure Rails Environment
ENV['RAILS_ENV'] = 'test'

require_relative '../test/dummy/config/environment'
ActiveRecord::Migrator.migrations_paths = [File.expand_path('../test/dummy/db/migrate', __dir__)]

require 'rails/test_help'
# Filter out Minitest backtrace while allowing backtrace from other libraries
# to be shown.
Minitest.backtrace_filter = Minitest::BacktraceFilter.new

require 'rails/test_unit/reporter'
Rails::TestUnitReporter.executable = 'bin/test'

# Load fixtures from the engine
if ActiveSupport::TestCase.respond_to?(:fixture_path=)
  ActiveSupport::TestCase.fixture_path = File.expand_path('fixtures', __dir__)
  ActionDispatch::IntegrationTest.fixture_path = ActiveSupport::TestCase.fixture_path
  ActiveSupport::TestCase.file_fixture_path = ActiveSupport::TestCase.fixture_path + '/files'
  ActiveSupport::TestCase.fixtures :all
end

class ActiveSupport::TestCase
  def self.at_least_rails61?
    ActiveStorage.version >= Gem::Version.new('6.1-alpha')
  end

  def at_least_rails61?
    self.class.at_least_rails61?
  end

  def image_file
    File.open(File.expand_path('fixtures/1px.png', __dir__))
  end
end

require 'yaml'
SERVICE_CONFIGURATIONS = begin
  erb = ERB.new(Pathname.new(File.expand_path('configurations.yml', __dir__)).read)
  configuration = YAML.load(erb.result) || {}
  configuration.deep_symbolize_keys
rescue Errno::ENOENT
  puts 'Missing service configuration file in test/configurations.yml'
  {}
end
