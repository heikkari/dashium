use Mix.Config

# Server settings
config :app, port: 4001
config :app, db_config: %{ name: "dev_db", pool_size: 3 }

# ID settings
config :app, id_epoch: 1293840000

# Security
config :app, accepted_email_domains: [ "gmail.com" ]

# Authentication. `min` and `max` are an array like [length, error code].
config :app, auth_limits: %{
  "userName" => [ min: [3, -9], max: [16, -4] ],
  "password" => [ min: [6, -8], max: [16, -5] ],
  "email"    => [ min: [3, -6], max: [32, -6] ]
}
