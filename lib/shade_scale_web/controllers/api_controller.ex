defmodule ShadeScaleWeb.ApiController do
  use ShadeScaleWeb, :controller

  def list_objects(conn, params) do
    [bucket | _] = String.split(conn.host, ".")

    # Return empty file listing
    # Needed for Tigris validating the shadow bucket
    send_resp(conn, 200, """
    <?xml version="1.0" encoding="UTF-8"?>
    <ListBucketResult>
       <IsTruncated>false</IsTruncated>
       <Name>#{bucket}</Name>
       <Prefix>/</Prefix>
       <Delimiter>#{params["delimiter"]}</Delimiter>
       <MaxKeys>#{params["max-keys"]}</MaxKeys>
       <EncodingType>url</EncodingType>
       <KeyCount>0</KeyCount>
       <ContinuationToken>#{params["continuation-token"]}</ContinuationToken>
    </ListBucketResult>
    """)
  end

  def get_objects(conn, params) do
    [bucket | _] = String.split(conn.host, ".")
    bucket_to_query = Application.get_env(:shade_scale, :custom_bucket, bucket)
    [scale | path] = params["path"]
    req = Req.new() |> ReqS3.attach()

    case Req.get(req, url: "s3://#{bucket_to_query}/#{path}", retry: false) do
      {:ok, %{status: 200, body: image}} when is_binary(image) ->
        {:ok, image} = Image.from_binary(image)
        {:ok, resized} = Image.thumbnail(image, scale)
        {:ok, bin} = Image.write(resized, :memory, suffix: Path.extname(path))

        conn
        |> put_resp_content_type(MIME.from_path(path), nil)
        |> put_resp_header("content-length", bin |> byte_size() |> Integer.to_string())
        |> send_resp(200, bin)

      {:ok, %{status: 200}} ->
        send_resp(conn, 404, "")

      {:ok, %{status: 404}} ->
        send_resp(conn, 404, "")

      {:ok, %{status: 500, body: body}} ->
        send_resp(conn, 500, body)
    end
  end
end
