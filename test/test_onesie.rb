require "minitest/autorun"
require "onesie"

class TestOnesie < MiniTest::Unit::TestCase
  def test_initialize
    app = Onesie.new nil

    assert_equal [], app.except
    assert_equal [], app.only
    assert_equal "/", app.path
  end

  def test_initialize_except
    app = Onesie.new nil, :except => "/foo"
    refute_nil app.except.first
  end

  def test_initialize_only
    app = Onesie.new nil, :only => "/foo"
    refute_nil app.only.first
  end

  def test_call_onesie_clear
    app     = make_app
    env     = make_env "REQUEST_URI" => "onesie.clear"
    session = env["rack.session"]

    session["onesie.path"] = "foo"

    app.call env
    refute_equal "foo", session["onesie.path"]
  end

  def test_call_except
    called = false
    app    = make_app(:except => "/foo") { called = true }
    env    = make_env

    env["REQUEST_URI"] = env["PATH_INFO"] = "/bar"
    status, headers, body = app.call env

    refute called
    assert_equal 302, status
    assert_match(/\/bar$/, headers["Location"])

    env["REQUEST_URI"] = env["PATH_INFO"] = "/foo"
    app.call env
    assert called
  end

  def test_call_only
    called = false
    app    = make_app(:only => "/foo") { called = true }
    env    = make_env

    env["REQUEST_URI"] = env["PATH_INFO"] = "/bar"
    app.call env
    assert called

    called = false
    env["REQUEST_URI"] = env["PATH_INFO"] = "/foo"
    status, headers, body = app.call env

    refute called
    assert_equal 302, status
    assert_match(/\/foo$/, headers["Location"])
  end

  def make_app *args, &block
    options = Hash === args.last ? args.pop : {}
    app = args.first || block
    Onesie.new app, { :log => false }.merge(options)
  end

  def make_env extras = {}
    {
      "rack.session"    => {},
      "rack.url_scheme" => "http",
    }.merge extras
  end
end
