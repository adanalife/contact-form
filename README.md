# contact-form

Small Sinatra app that backs the contact and AMA forms on
[dana.lol](https://www.dana.lol). A `POST /` sends the form fields as an
email; `GET /` just redirects to https://www.dana.lol.

The same endpoint powers both forms: if the submission includes an `email`
field it's treated as a contact request (sent from that address, or
`noreply@dana.lol` if blank); without one it's treated as an AMA question and
sent from `ama@dana.lol`.

## Configuration

The app reads three environment variables:

- `SENDGRID_USERNAME` / `SENDGRID_PASSWORD` — SendGrid SMTP credentials.
- `WHITELIST` — **space-separated** list of allowed origin URLs. This is the
  origin allowlist for form submissions; a comma-separated value is parsed as
  a single URL and will silently break origin protection.

Plus `EMAIL_RECIPIENTS` for where the mail goes.

## Deploying (Heroku)

The documented path is Heroku:

```
heroku create website-contact
heroku addons:add sendgrid:starter   # sets the SendGrid username/password
heroku config:set EMAIL_RECIPIENTS="you@example.com"
heroku config:set WHITELIST="https://www.yoursite.com/"
```

To allow multiple sites or domains, set `WHITELIST` to a space-separated
list of URLs.

On your site, point the form at the app:

```html
<form action="https://website-contact.herokuapp.com/" method="post">
```

Use as many fields as you want — the mail body is the `message` field.

## Tests

```
WHITELIST="http://example.com" bundle exec ruby test/test.rb
```
