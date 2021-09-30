use Mix.Config

# ID settings
config :app, id_epoch: 1293840000

# Quests
config :app, quests: [
  orbs: [
    names: [ "Orb Finder", "Orb Collector", "Orb Master" ],
    min: 500, max: 1500, diamond_multiplier: 0.5
  ],
  coins: [
    names: [ "Coin Finder", "Coin Collector", "Coin Master" ],
    min: 3, max: 9, diamond_multiplier: 3
  ],
  stars: [
    names: [ "Star Finder", "Star Collector", "Star Master" ],
    min: 10, max: 40, diamond_multiplier: 1
  ]
]

# Rewards
config :app, rewards: %{
  small: [
    orbs: [ min: 100, max: 200 ],
    diamonds: [ min: 1, max: 5 ],
    timeout_hours: 4
  ],
  large: [
    orbs: [ min: 100, max: 200 ],
    diamonds: [ min: 1, max: 5 ],
    timeout_hours: 24
  ]
}

# Pagination
config :app, limit: 10

# If a comment's like to dislike ratio is less than this, it will be flagged as spam.
# Likes / Dislikes
config :app, spam_ratio: 5 / 15

# Mod color
config :app, mod_colors: %{
  0 => [ 0xFF, 0xFF, 0xFF ], # Regular user
  1 => [ 0x00, 0xFF, 0x44 ], # Mod
  2 => [ 0x00, 0xFF, 0xFF ], # Elder Mod
}
