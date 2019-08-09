require 'minitest/autorun'

ENV['GH_ENV'] = 'bats'

vendor_dir = File.join(File.dirname(File.dirname(__FILE__)), "share/ruby/vendor")
ENV['GEM_PATH']="#{vendor_dir}/ruby/2.4.0:#{ENV['GEM_PATH']}"

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
end
