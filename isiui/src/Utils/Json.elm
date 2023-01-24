module Utils.Json exposing (maybeDecoder)

import Json.Decode as Decode exposing (Decoder)

maybeDecoder : Decoder a -> (a -> Maybe b) -> Decoder b
maybeDecoder startDecoder f =
  startDecoder
  |> Decode.andThen
      ( f >> Maybe.map Decode.succeed
          >> Maybe.withDefault (Decode.fail "Passed string is not a valid Email")
      )
