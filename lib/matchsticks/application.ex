defmodule Matchsticks.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      MatchsticksWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: Matchsticks.PubSub},
      # Start presence tracking
      MatchsticksWeb.Presence,
      # Start the Endpoint (http/https)
      MatchsticksWeb.Endpoint,
      # Start a worker by calling: Matchsticks.Worker.start_link(arg)
      # {Matchsticks.Worker, arg}
      Matchsticks.GameSupervisor
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Matchsticks.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    MatchsticksWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
