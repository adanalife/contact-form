# contact-form

Tiny Sinatra app that backs the contact and AMA forms on
[dana.lol](https://www.dana.lol). It accepts a `POST /` from the
website, sends the message as email via SMTP, and redirects the user
to a success page.

The same backend serves both `/contact` (has an `email` field) and
`/ama` (no `email` field — the message is treated as a question and
sent from `ama@<from-domain>`).

## Endpoints

| Method  | Path       | Behavior                                                          |
|---------|------------|-------------------------------------------------------------------|
| GET     | `/`        | 302 → `https://www.<from-domain>`                                 |
| POST    | `/`        | Sends the message as email; 302 → `<success-url>`                 |
| GET     | `/healthz` | `{"status":"ok"}` (k8s liveness/readiness probe)                  |
| OPTIONS | `/`        | Browser CORS preflight; allows allowlisted origins                |

## Configuration

All config is via environment variables.

| Var                | Default                                | Notes                                                           |
|--------------------|----------------------------------------|-----------------------------------------------------------------|
| `EMAIL_RECIPIENTS` | _(required)_                           | Recipient address(es) for delivered mail.                       |
| `ALLOWLIST`        | _(empty)_                              | Space-separated list of allowed `Origin` headers (CORS + CSRF). |
| `FROM_DOMAIN`      | `dana.lol`                             | Used for `noreply@`, `ama@`, and the success-URL default.       |
| `SUCCESS_URL`      | `https://www.<from-domain>/success`    | Where to redirect after successful POST.                        |
| `SMTP_HOST`        | `email-smtp.us-east-1.amazonaws.com`   | SES SMTP endpoint by default.                                   |
| `SMTP_PORT`        | `587`                                  |                                                                 |
| `SMTP_DOMAIN`      | `<from-domain>`                        | EHLO domain.                                                    |
| `SMTP_USERNAME`    | _(required)_                           | SMTP auth username.                                             |
| `SMTP_PASSWORD`    | _(required)_                           | SMTP auth password.                                             |

## Local development

Ruby is pinned via `.tool-versions` (mise). From non-interactive shells
(e.g. Claude Code's Bash tool), prefix `bundle` with `mise exec --`.

```bash
mise exec -- bundle install
mise exec -- bundle exec ruby test/test.rb           # run the test suite
mise exec -- bundle exec puma -b tcp://0.0.0.0:8080  # start locally
```

Tests run pony in `:test` mode, so SMTP credentials are not required
to run them.

## Container

Multi-stage Dockerfile, multi-arch image published as
`adanalife/contact-form:<version>` on Docker Hub via the `Release`
GitHub Actions workflow on `v*` tag pushes (matrix builds on native
amd64 + arm64 runners; the manifest job then combines them into a
multi-arch list).

```bash
docker build -t contact-form:dev .
docker run --rm -p 8080:8080 \
  -e EMAIL_RECIPIENTS=you@example.com \
  -e ALLOWLIST='https://www.dana.lol https://staging.dana.lol' \
  -e SMTP_USERNAME=... \
  -e SMTP_PASSWORD=... \
  contact-form:dev
```

## History

Forked from [evantravers/middleman-contact-form](https://github.com/evantravers/middleman-contact-form);
adapted to power both `/contact` and `/ama` on dana.lol. Originally
deployed to Heroku with the SendGrid addon; modernized in 2026 for
Ruby 3.4 + AWS SES SMTP and packaged for k8s deployment on the
adanalife stage-1 cluster.
