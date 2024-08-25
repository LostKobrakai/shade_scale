defmodule ShadeScaleWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :shade_scale

  plug :health

  # Code reloading can be explicitly enabled under the
  # :code_reloader configuration of your endpoint.
  if code_reloading? do
    plug Phoenix.CodeReloader
  end

  plug Plug.RequestId
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]
  plug Plug.Head
  plug ShadeScaleWeb.Router

  def health(conn, _) do
    case conn do
      %{request_path: "/health"} -> conn |> send_resp(200, "OK") |> halt()
      _ -> conn
    end
  end
end
