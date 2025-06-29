require 'simplecov'
SimpleCov.start do
  add_filter '/spec/'
  add_filter '/vendor/'
end

require 'bundler/setup'
require 'swarm_tasks'
require 'tmpdir'
require 'fileutils'

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.filter_run_when_matching :focus
  config.example_status_persistence_file_path = ".rspec_status"
  config.disable_monkey_patching!
  config.warnings = true

  if config.files_to_run.one?
    config.default_formatter = "doc"
  end

  config.profile_examples = 10
  config.order = :random
  Kernel.srand config.seed

  # Helper method to create a temporary directory for tests
  def with_temp_dir
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        yield dir
      end
    end
  end

  # Helper to capture stdout
  def capture_stdout
    original = $stdout
    io = StringIO.new
    
    # Mock TTY methods for table rendering
    io.define_singleton_method(:tty?) { false }
    io.define_singleton_method(:ioctl) { |*args| nil }
    io.define_singleton_method(:winsize) { [24, 80] }
    
    $stdout = io
    yield
    $stdout.string
  ensure
    $stdout = original
  end

  # Helper to suppress output during tests
  def suppress_output
    original_stdout = $stdout
    original_stderr = $stderr
    $stdout = StringIO.new
    $stderr = StringIO.new
    yield
  ensure
    $stdout = original_stdout
    $stderr = original_stderr
  end
end