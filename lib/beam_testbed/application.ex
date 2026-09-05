defmodule BeamTestbed.Application do
  # See https://elixir.hexdocs.pm/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      BeamTestbedWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:beam_testbed, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: BeamTestbed.PubSub},
      # Start a worker by calling: BeamTestbed.Worker.start_link(arg)
      # {BeamTestbed.Worker, arg},
      # Start to serve requests, typically the last entry
      BeamTestbedWeb.Endpoint
    ]

    # See https://elixir.hexdocs.pm/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: BeamTestbed.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    BeamTestbedWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
