module FlagsDecoding exposing (..)

import Json.Decode as Decode exposing (decodeString)
-- import Storage
import Test
import Expect
import Fuzz exposing (Fuzzer, int, list, string)
import Session.Session as Session
import Utils.Url exposing (emptyUrl)


-- import test

suite : Test.Test
suite =
  Test.describe "decodifica dei flags" [emptyViewerTest, apiUrlTest]
  -- Test.test "prova" <| \_ -> Expect.pass

emptyViewerFlags = """
    {"viewer":null,"api_url":"http://localhost:54321/rest/v1/"}
    """

emptyViewerTest : Test.Test
emptyViewerTest =
  Test.test "decodifica dei flag con solo `api_url`" <| 
    \_ -> case decodeString Session.apiUrlDecoder emptyViewerFlags of
        Ok _ ->
          Expect.pass

        Err _ ->
          Expect.fail "Failed to decode a valid api_url flag"


apiUrlTest : Test.Test
apiUrlTest =
  let
    loaded = Decode.decodeString Session.apiUrlDecoder emptyViewerFlags 
              |> Result.toMaybe
              |> Maybe.withDefault Utils.Url.emptyUrl

  in
  Test.test "caricamento dei flag con solo `api_url`" <| 
    \_ -> 
      if loaded == emptyUrl 
      then Expect.fail "Failed to load a valid api_url flag" 
      else Expect.pass
