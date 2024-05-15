import Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :matchsticks, MatchsticksWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "DUkIjbdbEhmW5BxAFf/Fow6Onw6/ah5PwdkBGxQb4J/7dsJ5gDGuNf2bu5HADoFC",
  server: false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime
