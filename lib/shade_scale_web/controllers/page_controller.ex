defmodule ShadeScaleWeb.PageController do
  use ShadeScaleWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
