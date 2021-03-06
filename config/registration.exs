use Mix.Config

# Security
config :app, accepted_email_domains: [ "gmail.com" ]
config :app, accepted_chars: "qwertyuioasdfghjklzxcvbnmQWERTYUIOPASDFGHJKLZXCVBNM1234567890/=_-"

# Authentication. `min` and `max` are an array like [length, error code].
config :app, auth_limits: %{
  "userName" => [ min: [3, -9], max: [16, -4] ],
  "password" => [ min: [6, -8], max: [16, -5] ],
  "email"    => [ min: [3, -6], max: [32, -6] ]
}
