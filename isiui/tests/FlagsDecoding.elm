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


-- viewerFlagTest : Test.Test
-- viewerFlagTest =
--   let
--     flags = """
--     { "api_url":"http://localhost:54321/rest/v1/"
--     , "viewer" : {
--         "provider_token": "ya29.a0AVvZVspIyIdzer4h0ab462Um9jnqmbiNTly9QDbvaNyrAHauS2-e8J3z90UUj5oLnmECkKLeYG_TZH3TMJDBYay4TvGc7FqOUEenp9j16ZdOur_Xv0iVisUY73REbVAalNT132hYFCSocgojfoIp4DroF6Y-kzAaCgYKAfESARASFQGbdwaIftkdUkm6tJPpuyzrXb00yg0166",
--         "provider_refresh_token": null,
--         "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhdWQiOiJhdXRoZW50aWNhdGVkIiwiZXhwIjoxNjc0NTE1OTY3LCJzdWIiOiI4YzY4YzQ4MC03ZGY5LTQxNGItYWUxNC02M2E4NWZkNDc1NzgiLCJlbWFpbCI6ImNvc3RhbnRpbi5naXVsaW9kb3JpQHN0dWRlbnRpLnVuaWNhbS5pdCIsInBob25lIjoiIiwiYXBwX21ldGFkYXRhIjp7InByb3ZpZGVyIjoiZ29vZ2xlIiwicHJvdmlkZXJzIjpbImdvb2dsZSJdfSwidXNlcl9tZXRhZGF0YSI6eyJhdmF0YXJfdXJsIjoiaHR0cHM6Ly9saDMuZ29vZ2xldXNlcmNvbnRlbnQuY29tL2EvQUVkRlRwNkxQdGRLNk03c0FXN3lMdVVxVzhxaEVWU0VVeEoxRGMzOXlFTVY9czk2LWMiLCJlbWFpbCI6ImNvc3RhbnRpbi5naXVsaW9kb3JpQHN0dWRlbnRpLnVuaWNhbS5pdCIsImVtYWlsX3ZlcmlmaWVkIjp0cnVlLCJmdWxsX25hbWUiOiJDT1NUQU5USU5PIEdJVUxJT0RPUkkiLCJpc3MiOiJodHRwczovL3d3dy5nb29nbGVhcGlzLmNvbS91c2VyaW5mby92Mi9tZSIsIm5hbWUiOiJDT1NUQU5USU5PIEdJVUxJT0RPUkkiLCJwaWN0dXJlIjoiaHR0cHM6Ly9saDMuZ29vZ2xldXNlcmNvbnRlbnQuY29tL2EvQUVkRlRwNkxQdGRLNk03c0FXN3lMdVVxVzhxaEVWU0VVeEoxRGMzOXlFTVY9czk2LWMiLCJwcm92aWRlcl9pZCI6IjExNzkyODM4NDA5OTIwNjE4NTUyMCIsInN1YiI6IjExNzkyODM4NDA5OTIwNjE4NTUyMCJ9LCJyb2xlIjoiYXV0aGVudGljYXRlZCIsImFhbCI6ImFhbDEiLCJhbXIiOlt7Im1ldGhvZCI6Im9hdXRoIiwidGltZXN0YW1wIjoxNjc0NTEyMzY3fV0sInNlc3Npb25faWQiOiI2NjM1ZGY1Yy1iNTYzLTQzYmQtYTdhZS03NmUwZGNhY2M3ZDQifQ.YdQbtie4JTHLgDxdRj1YA1zAd-eMwPrsfeA6Q-ih3Zk",
--         "expires_in": 3600,
--         "expires_at": 1674515969,
--         "refresh_token": "6X-CuMpHcY615r_Oz3mM1A",
--         "token_type": "bearer",
--         "user": {
--           "id": "8c68c480-7df9-414b-ae14-63a85fd47578",
--           "aud": "authenticated",
--           "role": "authenticated",
--           "email": "costantin.giuliodori@studenti.unicam.it",
--           "email_confirmed_at": "2023-01-23T22:13:05.642288Z",
--           "phone": "",
--           "confirmed_at": "2023-01-23T22:13:05.642288Z",
--           "last_sign_in_at": "2023-01-23T22:19:27.176925Z",
--           "app_metadata": {
--             "provider": "google",
--             "providers": [
--               "google"
--             ]
--           },
--           "user_metadata": {
--             "avatar_url": "https://lh3.googleusercontent.com/a/AEdFTp6LPtdK6M7sAW7yLuUqW8qhEVSEUxJ1Dc39yEMV=s96-c",
--             "email": "costantin.giuliodori@studenti.unicam.it",
--             "email_verified": true,
--             "full_name": "COSTANTINO GIULIODORI",
--             "iss": "https://www.googleapis.com/userinfo/v2/me",
--             "name": "COSTANTINO GIULIODORI",
--             "picture": "https://lh3.googleusercontent.com/a/AEdFTp6LPtdK6M7sAW7yLuUqW8qhEVSEUxJ1Dc39yEMV=s96-c",
--             "provider_id": "117928384099206185520",
--             "sub": "117928384099206185520"
--           },
--           "identities": [
--             {
--               "id": "117928384099206185520",
--               "user_id": "8c68c480-7df9-414b-ae14-63a85fd47578",
--               "identity_data": {
--                 "avatar_url": "https://lh3.googleusercontent.com/a/AEdFTp6LPtdK6M7sAW7yLuUqW8qhEVSEUxJ1Dc39yEMV=s96-c",
--                 "email": "costantin.giuliodori@studenti.unicam.it",
--                 "email_verified": true,
--                 "full_name": "COSTANTINO GIULIODORI",
--                 "iss": "https://www.googleapis.com/userinfo/v2/me",
--                 "name": "COSTANTINO GIULIODORI",
--                 "picture": "https://lh3.googleusercontent.com/a/AEdFTp6LPtdK6M7sAW7yLuUqW8qhEVSEUxJ1Dc39yEMV=s96-c",
--                 "provider_id": "117928384099206185520",
--                 "sub": "117928384099206185520"
--               },
--               "provider": "google",
--               "last_sign_in_at": "2023-01-23T22:13:05.637386Z",
--               "created_at": "2023-01-23T22:13:05.637442Z",
--               "updated_at": "2023-01-23T22:19:27.16884Z"
--             }
--           ],
--           "created_at": "2023-01-23T22:13:05.625762Z",
--           "updated_at": "2023-01-23T22:19:27.180042Z"
--         }
--       }
--     }
--     """
--   in
    