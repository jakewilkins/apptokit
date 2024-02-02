require 'pathname'
require 'minitest/autorun'

ENV['GH_ENV'] = 'bats'

TEST_DIR = Pathname.new(__FILE__).dirname
TMP_DIR = TEST_DIR.dirname.join("tmp")

TEST_HOME_DIR = TMP_DIR.join("home/#{ENV["RUBY_VERSION"]}")
TEST_HOME_CONFIG_DIR = TEST_HOME_DIR.join('.config')
TEST_HOME_APPTOKIT_DIR = TEST_HOME_CONFIG_DIR.join('apptokit')
TEST_GLOBAL_CONFIG = TEST_HOME_CONFIG_DIR.join('apptokit.yml')

TEST_LOCAL_CONFIG = Pathname.new(Dir.pwd).join('.apptokit.yml')
DEFAULT_TEST_GLOBAL_CONFIG = TEST_DIR.join('env.yml')

TEST_HOME_APPTOKIT_DIR.mkpath unless TEST_HOME_APPTOKIT_DIR.exist?

ENV["HOME"] = TEST_HOME_DIR.to_s

ENV["DEBUG"] = "config"

unless defined?(SETUP_SSH_RAN)
  SETUP_SSH_RAN = true

  current_dir = File.basename(Dir.pwd)
  in_ci_build_dir = current_dir == ENV["RUBY_VERSION"]
  in_test_dir = current_dir == "test"

  $path_prefix = if in_ci_build_dir || in_test_dir
    "../"
  else
    ""
  end

  system({"HOME" => ENV["HOME"]}, "#{$path_prefix}test/setup.sh")
end

require 'setup'

module AssertionHelpers
  # Asserts that two arrays contain the same elements, the same number of
  # times. Essentially ==, but unordered.
  def assert_same_elements(expected, actual, msg = nil)
    refute_kind_of Hash, expected, "assert_same_elements called with a hash instead of an array for the expected value"
    refute_kind_of Hash, actual, "assert_same_elements called with a hash instead of an array for the actual value"

    msg = [msg, "different elements"].compact.join(" - ")
    assert_equal expected.size, actual.size, msg

    same = true
    expected.each do |e1|
      expected_count = expected.select { |e2| e1 == e2 }.size
      actual_count = actual.select { |e2| e1 == e2 }.size
      unless expected_count == actual_count
        same = false
        break
      end
    end

    msg << "\nExpected #{expected} to have the same elements as #{actual}."
    assert same, msg
  end
end

class TestCase < Minitest::Test
  include AssertionHelpers

  def reset_global_config
    FileUtils.cp(DEFAULT_TEST_GLOBAL_CONFIG, TEST_GLOBAL_CONFIG)
  end

  def reset_local_config
    FileUtils.rm(TEST_LOCAL_CONFIG) if TEST_LOCAL_CONFIG.exist?
  end

  def reset!
    reset_global_config
    reset_local_config
  end

  def write_global_config(hash, env: 'bats')
    File.write(TEST_GLOBAL_CONFIG, {env => hash}.to_yaml)
  end

  def write_local_config(hash, env: 'bats')
    File.write(TEST_LOCAL_CONFIG, {env => hash}.to_yaml)
  end

  def teardown
    reset!
  end
end
