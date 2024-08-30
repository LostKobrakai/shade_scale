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
end
