import Config

# Do not print debug messages in production
config :logger, level: :info

config :shade_scale, ShadeScaleWeb.Endpoint,
  force_ssl: [
    rewrite_on: [:x_forwarded_host, :x_forwarded_port, :x_forwarded_proto],
    host: nil,
    hsts: true
  ]

# Runtime production configuration, including reading
# of environment variables, is done on config/runtime.exs.
