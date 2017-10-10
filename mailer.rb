require 'sinatra'
require 'pony'

before do
  headers['Access-Control-Allow-Methods'] = 'GET, POST, PUT, DELETE, OPTIONS'
  headers['Access-Control-Allow-Origin']  = '*'
  headers['Access-Control-Allow-Headers'] = 'accept, authorization, origin'
end

# whitelist should be a space separated list of URLs
whitelist = ENV['WHITELIST'].split

set :protection, origin_whitelist: whitelist

Pony.options = {
  via: :smtp,
  via_options: {
    address: 'smtp.sendgrid.net',
    port: '587',
    domain: 'heroku.com',
    user_name: ENV['SENDGRID_USERNAME'],
    password: ENV['SENDGRID_PASSWORD'],
    authentication:  :plain,
    enable_starttls_auto: true
  }
}

get '/' do
  redirect 'https://www.dana.lol'
end

post '/' do
  puts params

  to = ENV['EMAIL_RECIPIENTS']
  from = params[:email].empty? ? 'noreply@dana.lol' : params[:email]
  subject = "[danalol] new contact from #{request.ip}"
  body = params[:message]

  Pony.mail(
    to:      to,
    from:    from,
    subject: subject,
    body:    body
  )

  redirect 'https://www.dana.lol/success'
end
