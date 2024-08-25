defmodule ShadeScale.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      ShadeScaleWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:shade_scale, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: ShadeScale.PubSub},
      # Start a worker by calling: ShadeScale.Worker.start_link(arg)
      # {ShadeScale.Worker, arg},
      # Start to serve requests, typically the last entry
      ShadeScaleWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: ShadeScale.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    ShadeScaleWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
