use Mix.Config

config :app, anti_cheat: %{
  stars: [ max: nil, max_diff: 40 ],
  demons: [ max: nil, max_diff: 5 ],
  secret_coins: [ max: 149, max_diff: 6 ],
  user_coins: [ max: nil, max_diff: 6 ],
  diamonds: [ max: nil, max_diff: 10 ]
}
