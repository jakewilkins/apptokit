
require "test_helper"
require "apptokit/key_cache"

class KeyCacheTest < TestCase
  CONFIG_DIR = "#{ENV["HOME"]}/.config/apptokit"
  TEST_KEYCACHE = "./test/keycache.db"
  KEYCACHE = "#{ENV['HOME']}/.config/apptokit/.apptokit_bats_keycache"

  def setup
    FileUtils.mkdir_p(CONFIG_DIR)
    FileUtils.rm(KEYCACHE) if File.exist?(KEYCACHE)
    FileUtils.cp(TEST_KEYCACHE, KEYCACHE)
  end

  def cache
    @cache ||= Apptokit::KeyCache.new
  end

  def test_list_keys
    setup
    keys = cache.keys
    assert_same_elements keys, ["user:1410449:", "installation:1410449"]
  end

  def test_getting_keys
    setup
    key = cache.get("user:1410449:")
    assert_equal "a66c488331e082f8b904fcd51e62b398cdbbee2a", key
    key, expiry = cache.get("user:1410449:", return_expiry: true)
    assert_equal "a66c488331e082f8b904fcd51e62b398cdbbee2a", key
    assert_instance_of DateTime, expiry
  end

  def test_getting_expired_keys
    key = "test"
    value = "foobar"
    expiry = DateTime.new
    cache.set(key, value, expiry)

    fetched_value = cache.get(key, ignore_expiry: true)
    assert_equal "foobar", fetched_value

    fetched_value = cache.get(key)
    assert_nil fetched_value
  end

  def test_setting_keys
    key = "test"
    value = "foobar"
    expiry = DateTime.now + 10

    rvalue, rexpiry = cache.set(key, value, expiry, return_expiry: true)
    assert_equal value, rvalue
    assert_equal expiry.iso8601, rexpiry.iso8601

    assert_equal value, cache.get(key)

    rvalue, rexpiry = cache.get(key, return_expiry: true)
    assert_equal value, rvalue
    assert_equal expiry.iso8601, rexpiry.iso8601
  end

  def test_setting_keys_perists_between_instances
    key = "test"
    value = "foobar"
    expiry = DateTime.now + 10

    rvalue, rexpiry = cache.set(key, value, expiry, return_expiry: true)
    assert_equal value, rvalue
    assert_equal expiry.iso8601, rexpiry.iso8601

    assert_equal value, cache.get(key)

    rvalue, rexpiry = Apptokit::KeyCache.new.get(key, return_expiry: true)
    assert_equal value, rvalue
    assert_equal expiry.iso8601, rexpiry.iso8601
  end

  def test_dropping_keys
    key = "user:1410449:"
    refute_nil cache.get(key)
    cache.drop(key)
    assert_nil cache.get(key)
  end

  def test_dropping_keys_persists_between_instances
    key = "user:1410449:"
    refute_nil cache.get(key)
    cache.drop(key)
    assert_nil Apptokit::KeyCache.new.get(key)
  end

  def test_clearing_keys
    key = "user:1410449:"
    refute_nil cache.get(key)
    cache.clear
    assert_nil cache.get(key)

    assert_equal [], cache.keys
  end
end
