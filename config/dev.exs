use Mix.Config

# Server settings
config :app, port: 4001
config :app, db_config: %{ name: "dev_db", pool_size: 3 }

# ID settings
config :app, id_epoch: 1293840000

# Security
config :app, accepted_email_domains: [ "gmail.com" ]
