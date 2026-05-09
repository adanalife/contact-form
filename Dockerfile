FROM ruby:3.4-slim AS builder

RUN apt-get update \
 && apt-get install -y --no-install-recommends build-essential \
 && rm -rf /var/lib/apt/lists/*

ENV BUNDLE_DEPLOYMENT=true \
    BUNDLE_WITHOUT=test \
    BUNDLE_PATH=/usr/local/bundle

WORKDIR /app
COPY Gemfile Gemfile.lock ./
RUN bundle install --jobs 4 --retry 3


FROM ruby:3.4-slim AS runtime

ENV BUNDLE_DEPLOYMENT=true \
    BUNDLE_WITHOUT=test \
    BUNDLE_PATH=/usr/local/bundle \
    PORT=8080 \
    RACK_ENV=production

RUN groupadd -r app && useradd -r -g app -d /app app

WORKDIR /app
COPY --from=builder /usr/local/bundle /usr/local/bundle
COPY --chown=app:app . .

USER app
EXPOSE 8080

CMD ["bundle", "exec", "puma", "-b", "tcp://0.0.0.0:8080"]
