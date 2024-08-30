defmodule ShadeScaleWeb.PageHTML do
  @moduledoc """
  This module contains pages rendered by PageController.

  See the `page_html` directory for all templates available.
  """
  use ShadeScaleWeb, :html

  embed_templates "page_html/*"

  attr :src, :string, required: true
  attr :size, :any, default: {100, 100}
  attr :srcset, :list, default: [1, 2]
  attr :alt, :string, default: ""
  attr :rest, :global

  def image(assigns) do
    {size_w, size_h} = assigns.size

    sources =
      Enum.map(assigns.srcset, fn factor ->
        path =
          %ThumborPath{
            source: assigns.src,
            size: {size_w * factor, size_h * factor},
            filters: ["quality(85)"]
          }
          |> ThumborPath.build(ShadeScale.thumbor_secret())

        {Path.join(ShadeScale.thumbor_host(), path), factor}
      end)

    srcset = Enum.map_join(sources, ", ", fn {uri, factor} -> "#{uri} #{factor}x" end)

    assigns =
      assigns
      |> assign(:src, sources |> List.first() |> elem(0))
      |> assign(:srcset, srcset)

    ~H"""
    <img src={@src} alt={@alt} srcset={@srcset} {@rest} />
    """
  end
end
