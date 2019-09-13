
require "test_helper"
require "tempfile"
require "apptokit/key_cache"

class KeyCacheTest < TestCase

  TEST_KEYCACHE = Base64.encode64(JSON.generate({
    "user:1410449:" => "a66c488331e082f8b904fcd51e62b398cdbbee2a:::#{(DateTime.now + 600).iso8601}",
    "installation:1410449" => "v1.f6b9931aa49037765e58b6a2de56635098bb7f84:::#{(DateTime.now + 600).iso8601}"
  }))

  def setup_db(template: true)
    @db_file = Tempfile.new("bats_keycache")
    @cache = nil
    if template
      @db_file.write(TEST_KEYCACHE)
      @db_file.sync
      @db_file.rewind
    end
  end

  def teardown
    @db_file&.unlink
  end

  def cache
    @cache ||= Apptokit::KeyCache.new(path: @db_file.path)
  end

  def test_list_keys
    setup_db
    keys = cache.keys
    assert_same_elements keys, ["user:1410449:", "installation:1410449"]
  end

  def test_getting_keys
    setup_db
    key = cache.get("user:1410449:")
    assert_equal "a66c488331e082f8b904fcd51e62b398cdbbee2a", key
    key, expiry = cache.get("user:1410449:", return_expiry: true)
    assert_equal "a66c488331e082f8b904fcd51e62b398cdbbee2a", key
    assert_instance_of DateTime, expiry
  end

  def test_getting_expired_keys
    setup_db(template: false)
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
    setup_db(template: false)
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
    setup_db(template: false)
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
    setup_db
    key = "user:1410449:"
    refute_nil cache.get(key)
    cache.drop(key)
    assert_nil cache.get(key)
  end

  def test_dropping_keys_persists_between_instances
    setup_db
    key = "user:1410449:"
    refute_nil cache.get(key)
    cache.drop(key)
    assert_nil Apptokit::KeyCache.new.get(key)
  end

  def test_clearing_keys
    setup_db
    key = "user:1410449:"
    refute_nil cache.get(key)
    cache.clear
    assert_nil cache.get(key)

    assert_equal [], cache.keys
  end
end
