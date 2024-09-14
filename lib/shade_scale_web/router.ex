defmodule ShadeScaleWeb.Router do
  use ShadeScaleWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {ShadeScaleWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["xml"]
  end

  scope "/", ShadeScaleWeb do
    pipe_through :browser

    live "/", HomeLive
  end

  scope "/aws", ShadeScaleWeb do
    pipe_through :api

    get "/", ApiController, :list_objects
    forward "/", ImagePlug, secret: &ShadeScale.thumbor_secret/0
  end

  # Enable LiveDashboard in development
  if Application.compile_env(:shade_scale, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: ShadeScaleWeb.Telemetry
    end
  end
end
