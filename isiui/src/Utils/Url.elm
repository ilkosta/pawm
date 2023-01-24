module Utils.Url exposing(..)

import Url
import Json.Decode as Decode exposing (Decoder)
import Utils.Json

emptyUrl : Url.Url
emptyUrl =
    { host = ""
    , port_ = Nothing
    , protocol = Url.Http
    , path = "/"
    , query = Nothing
    , fragment = Nothing
    }

urlDecoder : Decoder Url.Url
urlDecoder =
  Utils.Json.maybeDecoder
    Decode.string
    Url.fromString