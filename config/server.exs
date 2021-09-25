use Mix.Config

# Server and database configuration
config :app, port: [ test: 4001, dev: 4001, prod: 8000 ]
config :app, db_config: [
  dev: [ name: "dev_db", pool_size: 3 ],
  test: [ name: "test_db", pool_size: 3 ],
  prod: [ name: "prod_db", pool_size: 3 ]
]

# XOR keys
config :app, xor: [
  authentication: "37526",
  user_profile: "85271",
  quests: "19847",
  rewards: "59182",
  messages: "14251"
]

# Salts
config :app, salt: [
  user_profile: "xI35fsAapCRg",
  rewards: "pC26fpYaQCtg",
  quests: "oC36fpYaPtdg",
]

config :app, save_server: "http://localhost:#{Application.get_env(:app, :port)[Mix.env()]}"
config :app, song_server: "https://www.newgrounds.com/audio/listen/"
config :app, top_artists: "http://www.boomlings.com/database/getGJTopArtists.php"
