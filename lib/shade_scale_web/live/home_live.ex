defmodule ShadeScaleWeb.HomeLive do
  use ShadeScaleWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex flex-col gap-4 items-center">
      <p>
        Files will be available publically, though with a random path. Use at your own risk.
      </p>
      <form
        :if={!@image}
        class="flex flex-col gap-4 items-center"
        id="upload-form"
        phx-change="validate"
        phx-submit="submit"
      >
        <div
          phx-drop-target={@uploads.image.ref}
          class="p-4 border-2 border-neutral-300 border-dashed rounded-lg"
        >
          <div class={[if(Enum.count(@uploads.image.entries) > 0, do: "hidden")]}>
            <.live_file_input upload={@uploads.image} />
          </div>
          <div :for={entry <- @uploads.image.entries} class="flex justify-around">
            <div>
              <.live_img_preview class="max-h-64" entry={entry} height="120" />
              <div><%= entry.progress %>%</div>
            </div>
          </div>
        </div>
        <.button>Upload</.button>
      </form>

      <div :if={@image} class="flex flex-col gap-4 items-center">
        <.image src={@image} size={{320, 0}} />
        <.image src={@image} size={{640, 0}} />
        <.image src={@image} size={{1280, 0}} />
      </div>
    </div>
    """
  end

  @impl true
  def mount(_, _, socket) do
    {:ok,
     socket
     |> assign(image: nil)
     |> allow_upload(:image,
       accept: ["image/jpeg", "image/png", "image/gif"],
       max_entries: 1,
       max_file_size: 15_000_000,
       external: &presign_upload/2
     )}
  end

  @impl true
  def handle_event("validate", _, socket) do
    {:noreply, socket}
  end

  def handle_event("submit", _, socket) do
    [image] =
      consume_uploaded_entries(socket, :image, fn %{key: key}, _entry ->
        {:ok, key}
      end)

    {:noreply, assign(socket, image: image)}
  end

  def presign_upload(entry, socket) do
    bin = :crypto.strong_rand_bytes(16)

    s3_options = [
      key: "uploads/#{Base.url_encode64(bin)}/#{entry.client_name}",
      bucket: Application.get_env(:shade_scale, :custom_bucket, "shade-scale")
    ]

    form =
      ReqS3.presign_form(
        [
          content_type: entry.client_type,
          max_size: 15_000_000
        ] ++ s3_options
      )

    meta = %{uploader: "S3", key: s3_options[:key], url: form.url, fields: Map.new(form.fields)}
    {:ok, meta, socket}
  end

  attr :src, :string, required: true
  attr :size, :any, default: {100, 100}
  attr :srcset, :list, default: [1, 2]
  attr :alt, :string, default: ""
  attr :rest, :global

  defp image(assigns) do
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
