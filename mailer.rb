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

  # this is a little janky, I'm using this project to power both the /contact and the /ama pages
  # the /ama page does not have an email field
  if params[:email]
    from = params[:email].empty? ? 'noreply@dana.lol' : params[:email]
    subject = "[danalol] new contact from #{request.ip}"
  else
    from = 'ama@dana.lol'
    subject = "[danalol] new AMA from #{request.ip}"
  end

  to = ENV['EMAIL_RECIPIENTS']
  body = params[:message]

  Pony.mail(
    to:      to,
    from:    from,
    subject: subject,
    body:    body
  )

  redirect 'https://www.dana.lol/success'
end
