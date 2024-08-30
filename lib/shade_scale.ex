defmodule ShadeScale do
  @moduledoc """
  ShadeScale keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """

  def thumbor_host do
    Application.get_env(:shade_scale, :thumbor_host)
  end

  def thumbor_secret do
    Application.get_env(:shade_scale, :thumbor_secret)
  end
end
