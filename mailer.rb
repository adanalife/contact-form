require 'sinatra'
require 'pony'

ALLOWLIST = (ENV['ALLOWLIST'] || '').split
FROM_DOMAIN = ENV['FROM_DOMAIN'] || 'dana.lol'
SUCCESS_URL = ENV['SUCCESS_URL'] || "https://www.#{FROM_DOMAIN}/success"

before do
  origin = request.env['HTTP_ORIGIN']
  if origin && ALLOWLIST.include?(origin)
    headers['Access-Control-Allow-Origin']  = origin
    headers['Access-Control-Allow-Methods'] = 'POST, OPTIONS'
    headers['Access-Control-Allow-Headers'] = 'accept, content-type, origin'
    headers['Vary'] = 'Origin'
  end
end

set :protection, origin_whitelist: ALLOWLIST  # rack-protection's API name is origin_whitelist

Pony.options = {
  via: :smtp,
  via_options: {
    address:              ENV['SMTP_HOST'] || 'email-smtp.us-east-1.amazonaws.com',
    port:                 (ENV['SMTP_PORT'] || '587').to_i,
    domain:               ENV['SMTP_DOMAIN'] || FROM_DOMAIN,
    user_name:            ENV['SMTP_USERNAME'],
    password:             ENV['SMTP_PASSWORD'],
    authentication:       :plain,
    enable_starttls_auto: true
  }
}

get '/healthz' do
  content_type :json
  '{"status":"ok"}'
end

get '/' do
  redirect "https://www.#{FROM_DOMAIN}"
end

options '/' do
  200
end

post '/' do
  logger.info(params.inspect)

  # the same backend serves both /contact (has email field) and /ama (does not)
  if params[:email]
    from = params[:email].empty? ? "noreply@#{FROM_DOMAIN}" : params[:email]
    subject = "[#{FROM_DOMAIN}] new contact from #{request.ip}"
  else
    from = "ama@#{FROM_DOMAIN}"
    subject = "[#{FROM_DOMAIN}] new AMA from #{request.ip}"
  end

  Pony.mail(
    to:      ENV['EMAIL_RECIPIENTS'],
    from:    from,
    subject: subject,
    body:    params[:message]
  )

  redirect SUCCESS_URL
end
