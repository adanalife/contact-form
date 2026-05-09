require File.expand_path '../test_helper.rb', __FILE__

class MailerTest < Minitest::Test
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def setup
    Pony.override_options = { via: :test }
    Mail::TestMailer.deliveries.clear
  end

  def test_healthz_returns_ok_json
    get '/healthz'
    assert last_response.ok?
    assert_equal 'application/json', last_response.content_type.split(';').first
    assert_equal({ 'status' => 'ok' }, JSON.parse(last_response.body))
  end

  def test_root_redirects_to_homepage
    get '/'
    assert_equal 302, last_response.status
    assert_includes last_response.location, 'dana.lol'
  end

  def test_post_with_email_sends_mail_and_redirects
    post '/', 'email' => 'visitor@example.com', 'message' => 'hello there'
    assert_equal 302, last_response.status
    assert_includes last_response.location, '/success'

    assert_equal 1, Mail::TestMailer.deliveries.size
    delivered = Mail::TestMailer.deliveries.first
    assert_equal ['visitor@example.com'], delivered.from
    assert_equal ['test@example.com'], delivered.to
    assert_includes delivered.body.to_s, 'hello there'
    assert_includes delivered.subject, 'new contact'
  end

  def test_post_with_blank_email_uses_noreply_from
    post '/', 'email' => '', 'message' => 'no return address'
    delivered = Mail::TestMailer.deliveries.first
    assert_equal ['noreply@dana.lol'], delivered.from
  end

  def test_post_without_email_field_treated_as_ama
    post '/', 'message' => 'how does the bot work?'
    delivered = Mail::TestMailer.deliveries.first
    assert_equal ['ama@dana.lol'], delivered.from
    assert_includes delivered.subject, 'new AMA'
  end

  def test_cors_header_echoed_for_whitelisted_origin
    header 'Origin', 'https://www.dana.lol'
    get '/healthz'
    assert_equal 'https://www.dana.lol', last_response.headers['Access-Control-Allow-Origin']
  end

  def test_cors_header_absent_for_unlisted_origin
    header 'Origin', 'https://evil.example.com'
    get '/healthz'
    assert_nil last_response.headers['Access-Control-Allow-Origin']
  end
end
