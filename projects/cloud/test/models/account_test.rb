# frozen_string_literal: true

require "test_helper"

class AccountTest < ActiveSupport::TestCase
  test "special characters are not allowed" do
    # Given
    subject = Account.new(name: "no!special?chars:allowed")

    # When
    subject.validate

    # Then
    assert_includes subject.errors.details[:name], { error: :invalid, value: "no!special?chars:allowed" }
  end

  test "white spaces are not allowed" do
    # Given
    subject = Account.new(name: "no whitespaces")

    # When
    subject.validate

    # Then
    assert_includes subject.errors.details[:name], { error: :invalid, value: "no whitespaces" }
  end

  test "valid name with dashes" do
    # Given
    owner = User.create!(email: "test@cloud.tuist.io", password: Devise.friendly_token.first(16))
    subject = Account.new(name: "name-with-dashes", owner: owner)

    # When
    subject.validate

    # Then
    assert_equal [], subject.errors.full_messages
  end

  test "valid name without dashes" do
    # Given
    owner = User.create!(email: "test@cloud.tuist.io", password: Devise.friendly_token.first(16))
    subject = Account.new(name: "namewithoutdashes", owner: owner)

    # When
    subject.validate

    # Then
    assert_equal [], subject.errors.full_messages
  end

  test "name's exclusion is validated" do
    # Given
    subject = Account.new(name: Defaults.fetch(:blocklisted_slug_keywords).first)

    # When
    subject.validate

    # Then
    assert_includes subject.errors.details[:name], { error: :exclusion, value: "new" }
  end
end
