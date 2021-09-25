<div style="text-align:center"><img src="assets/wordmark/wordmark.png" /></div>

Dashium is a GDPS written in Elixir, a functional language for building scalable and maintainable applications, leveraging the Erlang VM known for running low-latency, distributed, and fault-tolerant systems.

## Table of Contents

- [Installation](#installation)
- [Usage](#usage)
- [Progress](#progress)
- [Credits](#credits)

## Installation
1. Install the `erlang-dev` and `erlang-parsetools` packages. This will differ depending on your system.
2. [Install & run MongoDB](https://docs.mongodb.com/manual/installation/)
3. [Install MongoSH](https://docs.mongodb.com/mongodb-shell/install/)
4. Run the setup script: `mongosh < mongo_setup.js`
5. Clone the repository: `git clone https://github.com/heikkari/dashium.git`

## Usage

```
$ mix test
$ mix run --no-halt
```

## Progress

- ✅ Authentication (login, register, GJP)
- ✅ User Profiles (user info, user search, account settings, user score)
- 🚧 Scores
- ✅ Rewards
- ✅ Relationships
- ✅ Misc. (🚧 likeGJItem211)
- ✅ Messages
- 🚧 Levels
- 🚧 Level Packs
- 🚧 Comments

### TODO

- Caching
- Anti-cheat

## Credits

#### Libraries used:

- [plug_cowboy](https://github.com/elixir-plug/plug_cowboy)
- [mongodb_driver](https://github.com/zookzook/elixir-mongodb-driver)
- [argon2_elixir](https://github.com/riverrun/argon2_elixir)
- [exconstructor](https://github.com/appcues/exconstructor)
- [timex](https://github.com/bitwalker/timex)
- [floki](https://github.com/philss/floki)
