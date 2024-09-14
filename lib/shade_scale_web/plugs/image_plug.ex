defmodule ShadeScaleWeb.ImagePlug do
  use Plug.Builder
  import Plug.Conn

  plug :check_hmac
  plug :fetch_from_source
  plug :apply_transformations

  def init(opts) do
    %{secret: Keyword.fetch!(opts, :secret)}
  end

  def call(conn, opts) do
    secret =
      case opts.secret do
        secret when is_binary(secret) -> secret
        secret when is_function(secret, 0) -> secret.()
      end

    conn
    |> assign(:secret, secret)
    |> super([])
  end

  defp check_hmac(conn, _) do
    # hack to deal with S3 not allowing %2F as encoded / character on files/paths,
    # hence this service receiving them unencoded
    {thumbor, source_path} = Enum.split_while(conn.path_info, &(&1 != "uploads"))

    path =
      thumbor
      |> Path.join()
      |> URI.decode()
      |> Path.join(Enum.join(source_path, URI.encode_www_form("/")))

    if ThumborPath.valid?(path, conn.assigns.secret) do
      %ThumborPath{} = thumbor_path = ThumborPath.parse(path)
      assign(conn, :thumbor_path, thumbor_path)
    else
      conn
      |> send_resp(:forbidden, "")
      |> halt()
    end
  end

  defp fetch_from_source(conn, _) do
    [bucket | _] = String.split(conn.host, ".")
    bucket_to_query = Application.get_env(:shade_scale, :custom_bucket, bucket)
    %ThumborPath{source: path} = conn.assigns.thumbor_path
    req = Req.new() |> ReqS3.attach()

    case Req.get(req, url: "s3://#{bucket_to_query}/#{path}", retry: false) do
      {:ok, %{status: 200, body: image}} when is_binary(image) ->
        assign(conn, :source, image)

      {:ok, %{status: status}} when status in [200, 404] ->
        conn |> send_resp(404, "") |> halt()

      {:ok, %{status: 500, body: body}} ->
        conn |> send_resp(500, body) |> halt()
    end
  end

  defp apply_transformations(conn, _) do
    %ThumborPath{} = thumbor_path = conn.assigns.thumbor_path

    {:ok, image} = Image.from_binary(conn.assigns.source)
    {width, height, _} = Image.shape(image)

    crop =
      if width <= height do
        case thumbor_path.vertical_align || :middle do
          :top -> :high
          :middle -> :center
          :bottom -> :low
        end
      else
        case thumbor_path.horizontal_align || :center do
          :left -> :high
          :center -> :center
          :right -> :low
        end
      end

    opts =
      case thumbor_path.fit do
        :default -> [crop: crop]
        {:fit, _} -> [crop: :none, resize: :both]
      end

    image =
      Enum.reduce(thumbor_path |> Map.from_struct(), image, fn
        {:size, {a, b}}, image ->
          Image.thumbnail!(
            image,
            size_and_dimensions_to_thumbnail({a, b}, {width, height}),
            opts
          )

        _, image ->
          image
      end)

    opts =
      thumbor_path.filters
      |> Enum.flat_map(fn filter ->
        case Code.string_to_quoted(filter) do
          {:ok, {:quality, _, [parameter]}} when parameter in 1..100 -> [{:quality, parameter}]
          {:ok, _} -> []
        end
      end)
      |> Enum.into(%{quality: 100})

    {:ok, bin} =
      Image.write(image, :memory,
        suffix: Path.extname(thumbor_path.source),
        quality: opts.quality
      )

    conn
    |> put_resp_content_type(MIME.from_path(thumbor_path.source), nil)
    |> put_resp_header("content-length", bin |> byte_size() |> Integer.to_string())
    |> send_resp(200, bin)
  end

  defp size_and_dimensions_to_thumbnail({0, b}, {w, h}) do
    a = trunc(w / h * b)
    size_and_dimensions_to_thumbnail({a, b}, {w, h})
  end

  defp size_and_dimensions_to_thumbnail({a, 0}, {w, h}) do
    b = trunc(h / w * a)
    size_and_dimensions_to_thumbnail({a, b}, {w, h})
  end

  defp size_and_dimensions_to_thumbnail({a, b}, _), do: "#{a}x#{b}"
end
