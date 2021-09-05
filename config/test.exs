use Mix.Config

# Server settings
config :app, port: 4001
config :app, db_config: %{ name: "test_db", pool_size: 3 }

# ID settings
config :app, id_epoch: 1293840000

# Security
config :app, accepted_email_domains: [ "gmail.com" ]
config :app, accepted_chars: "qwertyuioasdfghjklzxcvbnmQWERTYUIOPASDFGHJKLZXCVBNM1234567890/="

# Anti-cheat
config :app, anti_cheat: %{
  stars: [ max: nil, max_diff: 40 ],
  demons: [ max: nil, max_diff: 5 ],
  secret_coins: [ max: 149, max_diff: 6 ],
  user_coins: [ max: nil, max_diff: 6 ],
  diamonds: [ max: nil, max_diff: 10 ]
}

# XOR keys
config :app, xor: [
  authentication: "37526",
  user_profile: "85271",
]

# Salts
config :app, salt: [
  user_profile: "xI35fsAapCRg",
]

# Authentication. `min` and `max` are an array like [length, error code].
config :app, auth_limits: %{
  "userName" => [ min: [3, -9], max: [16, -4] ],
  "password" => [ min: [6, -8], max: [16, -5] ],
  "email"    => [ min: [3, -6], max: [32, -6] ]
}
