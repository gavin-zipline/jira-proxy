# frozen_string_literal: true

max_threads_count = Integer(ENV.fetch("PUMA_MAX_THREADS", 5))
min_threads_count = Integer(ENV.fetch("PUMA_MIN_THREADS", max_threads_count))
threads min_threads_count, max_threads_count

port ENV.fetch("PORT", 4567)
environment ENV.fetch("RACK_ENV", "development")

worker_count = Integer(ENV.fetch("WEB_CONCURRENCY", 0))
workers worker_count if worker_count.positive?

preload_app! if worker_count.positive?

plugin :tmp_restart
