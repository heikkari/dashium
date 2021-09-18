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
  rewards: "59182"
]

# Salts
config :app, salt: [
  user_profile: "xI35fsAapCRg",
  rewards: "pC26fpYaQCtg",
  quests: "oC36fpYaPtdg",
]