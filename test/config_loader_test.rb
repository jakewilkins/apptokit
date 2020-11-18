# frozen_string_literal: true

require "test_helper"
require "tempfile"

class ConfigLoaderTest < TestCase

  def setup
    @loader = Apptokit::ConfigLoader.new
  end

  def test_loads_conf_from_home_dir
    @loader.reload!
    assert_equal @loader.env, 'bats'
    assert_equal @loader.fetch('private_key_path'), './bats_private_key.pem'
  end

  def test_loads_conf_from_project_dir
    write_local_config('user_agent' => 'test')

    p ENV.keys
    p ENV["HOME"]
    @loader.reload!
    p @loader.send(:config)

    assert_equal 'bats', @loader.env
    assert_equal './bats_private_key.pem', @loader.fetch('private_key_path')
    assert_equal 'test', @loader.fetch('user_agent')
  end

  def test_loads_conf_from_env
    write_local_config('user_agent' => 'test', 'client_id' => '1')
    ENV['APPTOKIT_USER_AGENT'] = 'foobar'

    @loader.reload!

    assert_equal 'bats', @loader.env
    assert_equal '1', @loader.fetch('client_id')
    assert_equal './bats_private_key.pem', @loader.fetch('private_key_path')
    assert_equal 'foobar', @loader.fetch('user_agent')
  ensure
    ENV.delete('APPTOKIT_USER_AGENT')
  end

  def test_loads_cached_manifest_env_file
    manifest_apps_dir = TEST_HOME_APPTOKIT_DIR.join('manifest_apps')
    manifest_apps_dir.mkpath unless manifest_apps_dir.exist?
    path = manifest_apps_dir.join('bats.yml')
    FileUtils.cp(TEST_DIR.join("manifest-app-env.yml"), path)
    write_local_config('manifest' => {'default_permissions' => {'issues' => 'read'}})

    @loader.reload!

    assert_equal 'noarealwebooksecret', @loader.fetch('webhook_secret')
    assert_equal 1, @loader.fetch('installation_id')
    assert_equal 'Iv1.notreal', @loader.fetch('client_id')
    assert_equal 'notarealsecret', @loader.fetch('client_secret')
  ensure
    FileUtils.rm(path) if path.exist?
  end

  def test_loads_example_env_file
    FileUtils.cp(TEST_DIR.dirname.join("share/apptokit-full-template.yml"), TEST_GLOBAL_CONFIG)
    ENV.delete('GH_ENV')

    if TEST_GLOBAL_CONFIG.exist?
      p ENV.keys
      puts TEST_GLOBAL_CONFIG.read
    else
      puts TEST_GLOBAL_CONFIG
      puts "doesn't exist?"
      puts TEST_DIR
    end
    @loader.reload!

    assert_equal 'test', @loader.env
    assert_equal 42, @loader.fetch('app_id')
    assert_equal '/home/user/downloads/test-app.*.pem', @loader.fetch('private_key_path_glob')
    assert_equal 8675309, @loader.fetch('installation_id')
    assert_equal 'Iv1.thisisnotatestid', @loader.fetch('client_id')
    assert_equal '25fthisisnotaclientsecret', @loader.fetch('client_secret')
  ensure
    ENV['GH_ENV'] = 'bats'
  end
end
