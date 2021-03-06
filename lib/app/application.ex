defmodule App.Application do
  @moduledoc false

  use Application
  require Logger

  def start(_type, _args) do
    env = Mix.env()
    [ name: name, pool_size: pool_size ] = Application.get_env(:app, :db_config)[env]
    port = Application.get_env(:app, :port)[env]

    # Required for :httpc & :crypto
    Application.ensure_all_started(:inets)
    Application.ensure_all_started(:ssl)

    children = [
      {Plug.Cowboy, scheme: :http, plug: Router, options: [port: port]},
      %{
        id: Mongo,
        start: { Mongo, :start_link, [[ name: :mongo, database: name, pool_size: pool_size ]] }
      }
    ]

    opts = [strategy: :one_for_one, name: App.Supervisor]

    Logger.info "Listening to port #{port}."
    Supervisor.start_link(children, opts)
  end
end
