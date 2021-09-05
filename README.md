# Dashium

<div style="text-align:center"><img src="assets/wordmark/wordmark.png" /></div>

Dashium is a GDPS written in Elixir, a functional language for building scalable and maintainable applications, leveraging the Erlang VM known for running low-latency, distributed, and fault-tolerant systems.

## Table of Contents

- [Installation](#installation)
- [Usage](#usage)
- [Progress](#progress)
- [Contributing](#contributing)
- [Credits](#credits)

## Installation

1. [Install & run MongoDB](https://docs.mongodb.com/manual/installation/)
2. [Install MongoSH](https://docs.mongodb.com/mongodb-shell/install/)
3. Run the setup script: `mongosh < mongo_setup.js`
4. Clone the repository: `git clone https://github.com/heikkari/dashium.git`

## Usage

```
$ mix test
$ mix run --no-halt
```

## Progress

- ✅ Authentication (login, register, GJP)
- ✅ User Profiles (user info, user search, account settings, user score)
- 🚧 Scores
- 🚧 Rewards
- 🚧 Relationships
- 🚧 Misc. (song info, account URL, ...)
- 🚧 Messages
- 🚧 Levels
- 🚧 Level Packs
- 🚧 Comments

## Contributing

1. Fork the repository.
2. Follow these instructions:
```
$ git clone https://github.com/heikkari/dashium.git
$ cd dashium
$ git checkout -b your-feature
$ mix test # Make sure you have a test for your new feature.
$ git add . # Your changes will be added here
$ git commit -m "Your commit message"
$ git remote set-url origin https://github.com/your-forked-repo
$ git push -u origin your-feature
```
3. [Open a PR with your branch.](https://github.com/heikkari/dashium/compare)


## Credits

#### Libraries used:

- [plug_cowboy](https://github.com/elixir-plug/plug_cowboy)
- [mongodb_driver](https://github.com/zookzook/elixir-mongodb-driver)
- [argon2_elixir](https://github.com/riverrun/argon2_elixir)
- [exconstructor](https://github.com/appcues/exconstructor)
