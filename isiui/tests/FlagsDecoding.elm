module FlagsDecoding exposing (..)

import Json.Decode as Decode exposing (decodeString)
-- import Storage
import Test
import Expect
import Fuzz exposing (Fuzzer, int, list, string)
import Session.Session as Session
import Utils.Url exposing (emptyUrl)
import Api


-- import test

suite : Test.Test
suite =
  Test.describe "decodifica dei flags" [emptyViewerTest, apiUrlTest]
  -- Test.test "prova" <| \_ -> Expect.pass

emptyViewerFlags = """
    {"viewer":null,"api_url":"http://localhost:54321/rest/v1/"}
    """

testErr : String -> Result Decode.Error a ->  Expect.Expectation
testErr errMsg res  = 
  case res of
    Ok _ ->
      Expect.pass

    Err e ->
      Expect.fail <| errMsg ++ " : " ++ (Decode.errorToString e)



apiUrlTestSuite : Test.Test
apiUrlTestSuite = 
  Test.describe "decodifica di api_url nei flags" 
    [emptyViewerTest, apiUrlTest]


emptyViewerTest : Test.Test
emptyViewerTest =
  Test.test "decodifica dei flag con solo `api_url`" <| 
    \_ -> 
      testErr "Failed to decode a valid api_url flag"
        (decodeString Session.apiUrlDecoder emptyViewerFlags)
      


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


viewerFlagTest : Test.Test
viewerFlagTest =
  let
    -- flags = """
    -- {"viewer":"{\"provider_token\":\"ya29.a0AVvZVsoKIpyyw7DTbkwri01BtN62Ngh514afTGa5z_vd_WOp6BRPgPlN0hR6U0t_i6vEuTuTscFOA7RFYwz0yk0dt1bTn0wGJ24kvDT7-HVSBSp5LUp9oon3fe0IvBk2Tj4u-oeaWd4nlm9UHCHkXZNGlqXZsdMaCgYKAQASARASFQGbdwaIPiRe0h_Kz4OpNV5teXC1vQ0166\",\"provider_refresh_token\":null,\"access_token\":\"eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhdWQiOiJhdXRoZW50aWNhdGVkIiwiZXhwIjoxNjc0NjAyNTE5LCJzdWIiOiIwMjQyZjY3YS01ZDk1LTQ3ZTYtOGU3Yi02ZTY5NGQ2M2M3MmUiLCJlbWFpbCI6ImNvc3RhbnRpbi5naXVsaW9kb3JpQHN0dWRlbnRpLnVuaWNhbS5pdCIsInBob25lIjoiIiwiYXBwX21ldGFkYXRhIjp7InByb3ZpZGVyIjoiZ29vZ2xlIiwicHJvdmlkZXJzIjpbImdvb2dsZSJdfSwidXNlcl9tZXRhZGF0YSI6eyJhdmF0YXJfdXJsIjoiaHR0cHM6Ly9saDMuZ29vZ2xldXNlcmNvbnRlbnQuY29tL2EvQUVkRlRwNkxQdGRLNk03c0FXN3lMdVVxVzhxaEVWU0VVeEoxRGMzOXlFTVY9czk2LWMiLCJlbWFpbCI6ImNvc3RhbnRpbi5naXVsaW9kb3JpQHN0dWRlbnRpLnVuaWNhbS5pdCIsImVtYWlsX3ZlcmlmaWVkIjp0cnVlLCJmdWxsX25hbWUiOiJDT1NUQU5USU5PIEdJVUxJT0RPUkkiLCJpc3MiOiJodHRwczovL3d3dy5nb29nbGVhcGlzLmNvbS91c2VyaW5mby92Mi9tZSIsIm5hbWUiOiJDT1NUQU5USU5PIEdJVUxJT0RPUkkiLCJwaWN0dXJlIjoiaHR0cHM6Ly9saDMuZ29vZ2xldXNlcmNvbnRlbnQuY29tL2EvQUVkRlRwNkxQdGRLNk03c0FXN3lMdVVxVzhxaEVWU0VVeEoxRGMzOXlFTVY9czk2LWMiLCJwcm92aWRlcl9pZCI6IjExNzkyODM4NDA5OTIwNjE4NTUyMCIsInN1YiI6IjExNzkyODM4NDA5OTIwNjE4NTUyMCJ9LCJyb2xlIjoiYXV0aGVudGljYXRlZCIsImFhbCI6ImFhbDEiLCJhbXIiOlt7Im1ldGhvZCI6Im9hdXRoIiwidGltZXN0YW1wIjoxNjc0NTk4OTE5fV0sInNlc3Npb25faWQiOiJmNDdjYmJkMC03NDVkLTQwNTQtODY0Ny1jMzcxY2E4ZmI2OTIifQ.9O6Eev138b4C65eu7luVVDG56zcX00EyACqprfxYVIY\",\"expires_in\":3600,\"expires_at\":1674602523,\"refresh_token\":\"bBIzfKBB-uqMWkPS_WryyA\",\"token_type\":\"bearer\",\"user\":{\"id\":\"0242f67a-5d95-47e6-8e7b-6e694d63c72e\",\"aud\":\"authenticated\",\"role\":\"authenticated\",\"email\":\"costantin.giuliodori@studenti.unicam.it\",\"email_confirmed_at\":\"2023-01-24T22:21:59.917394Z\",\"phone\":\"\",\"confirmed_at\":\"2023-01-24T22:21:59.917394Z\",\"last_sign_in_at\":\"2023-01-24T22:21:59.918297Z\",\"app_metadata\":{\"provider\":\"google\",\"providers\":[\"google\"]},\"user_metadata\":{\"avatar_url\":\"https://lh3.googleusercontent.com/a/AEdFTp6LPtdK6M7sAW7yLuUqW8qhEVSEUxJ1Dc39yEMV=s96-c\",\"email\":\"costantin.giuliodori@studenti.unicam.it\",\"email_verified\":true,\"full_name\":\"COSTANTINO GIULIODORI\",\"iss\":\"https://www.googleapis.com/userinfo/v2/me\",\"name\":\"COSTANTINO GIULIODORI\",\"picture\":\"https://lh3.googleusercontent.com/a/AEdFTp6LPtdK6M7sAW7yLuUqW8qhEVSEUxJ1Dc39yEMV=s96-c\",\"provider_id\":\"117928384099206185520\",\"sub\":\"117928384099206185520\"},\"identities\":[{\"id\":\"117928384099206185520\",\"user_id\":\"0242f67a-5d95-47e6-8e7b-6e694d63c72e\",\"identity_data\":{\"avatar_url\":\"https://lh3.googleusercontent.com/a/AEdFTp6LPtdK6M7sAW7yLuUqW8qhEVSEUxJ1Dc39yEMV=s96-c\",\"email\":\"costantin.giuliodori@studenti.unicam.it\",\"email_verified\":true,\"full_name\":\"COSTANTINO GIULIODORI\",\"iss\":\"https://www.googleapis.com/userinfo/v2/me\",\"name\":\"COSTANTINO GIULIODORI\",\"picture\":\"https://lh3.googleusercontent.com/a/AEdFTp6LPtdK6M7sAW7yLuUqW8qhEVSEUxJ1Dc39yEMV=s96-c\",\"provider_id\":\"117928384099206185520\",\"sub\":\"117928384099206185520\"},\"provider\":\"google\",\"last_sign_in_at\":\"2023-01-24T22:21:59.911371Z\",\"created_at\":\"2023-01-24T22:21:59.911424Z\",\"updated_at\":\"2023-01-24T22:21:59.911424Z\"}],\"created_at\":\"2023-01-24T22:21:59.90326Z\",\"updated_at\":\"2023-01-24T22:21:59.924121Z\"}}","api_url":"http://localhost:54321/rest/v1/"}
    -- """
    -- flags = """
    -- {"viewer":{"provider_token":"ya29.a0AVvZVsoKIpyyw7DTbkwri01BtN62Ngh514afTGa5z_vd_WOp6BRPgPlN0hR6U0t_i6vEuTuTscFOA7RFYwz0yk0dt1bTn0wGJ24kvDT7-HVSBSp5LUp9oon3fe0IvBk2Tj4u-oeaWd4nlm9UHCHkXZNGlqXZsdMaCgYKAQASARASFQGbdwaIPiRe0h_Kz4OpNV5teXC1vQ0166","provider_refresh_token":null,"access_token":"eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhdWQiOiJhdXRoZW50aWNhdGVkIiwiZXhwIjoxNjc0NjAyNTE5LCJzdWIiOiIwMjQyZjY3YS01ZDk1LTQ3ZTYtOGU3Yi02ZTY5NGQ2M2M3MmUiLCJlbWFpbCI6ImNvc3RhbnRpbi5naXVsaW9kb3JpQHN0dWRlbnRpLnVuaWNhbS5pdCIsInBob25lIjoiIiwiYXBwX21ldGFkYXRhIjp7InByb3ZpZGVyIjoiZ29vZ2xlIiwicHJvdmlkZXJzIjpbImdvb2dsZSJdfSwidXNlcl9tZXRhZGF0YSI6eyJhdmF0YXJfdXJsIjoiaHR0cHM6Ly9saDMuZ29vZ2xldXNlcmNvbnRlbnQuY29tL2EvQUVkRlRwNkxQdGRLNk03c0FXN3lMdVVxVzhxaEVWU0VVeEoxRGMzOXlFTVY9czk2LWMiLCJlbWFpbCI6ImNvc3RhbnRpbi5naXVsaW9kb3JpQHN0dWRlbnRpLnVuaWNhbS5pdCIsImVtYWlsX3ZlcmlmaWVkIjp0cnVlLCJmdWxsX25hbWUiOiJDT1NUQU5USU5PIEdJVUxJT0RPUkkiLCJpc3MiOiJodHRwczovL3d3dy5nb29nbGVhcGlzLmNvbS91c2VyaW5mby92Mi9tZSIsIm5hbWUiOiJDT1NUQU5USU5PIEdJVUxJT0RPUkkiLCJwaWN0dXJlIjoiaHR0cHM6Ly9saDMuZ29vZ2xldXNlcmNvbnRlbnQuY29tL2EvQUVkRlRwNkxQdGRLNk03c0FXN3lMdVVxVzhxaEVWU0VVeEoxRGMzOXlFTVY9czk2LWMiLCJwcm92aWRlcl9pZCI6IjExNzkyODM4NDA5OTIwNjE4NTUyMCIsInN1YiI6IjExNzkyODM4NDA5OTIwNjE4NTUyMCJ9LCJyb2xlIjoiYXV0aGVudGljYXRlZCIsImFhbCI6ImFhbDEiLCJhbXIiOlt7Im1ldGhvZCI6Im9hdXRoIiwidGltZXN0YW1wIjoxNjc0NTk4OTE5fV0sInNlc3Npb25faWQiOiJmNDdjYmJkMC03NDVkLTQwNTQtODY0Ny1jMzcxY2E4ZmI2OTIifQ.9O6Eev138b4C65eu7luVVDG56zcX00EyACqprfxYVIY","expires_in":3600,"expires_at":1674602523,"refresh_token":"bBIzfKBB-uqMWkPS_WryyA","token_type":"bearer","user":{"id":"0242f67a-5d95-47e6-8e7b-6e694d63c72e","aud":"authenticated","role":"authenticated","email":"costantin.giuliodori@studenti.unicam.it","email_confirmed_at":"2023-01-24T22:21:59.917394Z","phone":"","confirmed_at":"2023-01-24T22:21:59.917394Z","last_sign_in_at":"2023-01-24T22:21:59.918297Z","app_metadata":{"provider":"google","providers":["google"]},"user_metadata":{"avatar_url":"https://lh3.googleusercontent.com/a/AEdFTp6LPtdK6M7sAW7yLuUqW8qhEVSEUxJ1Dc39yEMV=s96-c","email":"costantin.giuliodori@studenti.unicam.it","email_verified":true,"full_name":"COSTANTINO GIULIODORI","iss":"https://www.googleapis.com/userinfo/v2/me","name":"COSTANTINO GIULIODORI","picture":"https://lh3.googleusercontent.com/a/AEdFTp6LPtdK6M7sAW7yLuUqW8qhEVSEUxJ1Dc39yEMV=s96-c","provider_id":"117928384099206185520","sub":"117928384099206185520"},"identities":[{"id":"117928384099206185520","user_id":"0242f67a-5d95-47e6-8e7b-6e694d63c72e","identity_data":{"avatar_url":"https://lh3.googleusercontent.com/a/AEdFTp6LPtdK6M7sAW7yLuUqW8qhEVSEUxJ1Dc39yEMV=s96-c","email":"costantin.giuliodori@studenti.unicam.it","email_verified":true,"full_name":"COSTANTINO GIULIODORI","iss":"https://www.googleapis.com/userinfo/v2/me","name":"COSTANTINO GIULIODORI","picture":"https://lh3.googleusercontent.com/a/AEdFTp6LPtdK6M7sAW7yLuUqW8qhEVSEUxJ1Dc39yEMV=s96-c","provider_id":"117928384099206185520","sub":"117928384099206185520"},"provider":"google","last_sign_in_at":"2023-01-24T22:21:59.911371Z","created_at":"2023-01-24T22:21:59.911424Z","updated_at":"2023-01-24T22:21:59.911424Z"}],"created_at":"2023-01-24T22:21:59.90326Z","updated_at":"2023-01-24T22:21:59.924121Z"}},"api_url":"http://localhost:54321/rest/v1/"}
    -- """
    flags = """
    {"viewer":{"provider_token":"ya29.a0AVvZVsqIEnmVCKeTt0vO7pfo6rPvLpTvLsp8rWzfFOwkQkAaCLOLm6MSBfP0uyYnDgj3epcLpvSEg3VjgkIwGe0Kmujt_dww8GchmxmROByQrm9QuapgfaEtnd6SfKvFc4j2crBqLOLB7yWbKvgKE0YpOa8kXcgaCgYKAYcSARASFQGbdwaIXwJGTPB3e0RltgVlZL4wIw0166","provider_refresh_token":null,"access_token":"eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhdWQiOiJhdXRoZW50aWNhdGVkIiwiZXhwIjoxNjc0NjA2OTM0LCJzdWIiOiI2N2Y2MjA3ZS1mZWNhLTRiMzUtYjEyZi0wNmNhODFkODBjZjEiLCJlbWFpbCI6ImNvc3RhbnRpbi5naXVsaW9kb3JpQHN0dWRlbnRpLnVuaWNhbS5pdCIsInBob25lIjoiIiwiYXBwX21ldGFkYXRhIjp7InByb3ZpZGVyIjoiZ29vZ2xlIiwicHJvdmlkZXJzIjpbImdvb2dsZSJdfSwidXNlcl9tZXRhZGF0YSI6eyJhdmF0YXJfdXJsIjoiaHR0cHM6Ly9saDMuZ29vZ2xldXNlcmNvbnRlbnQuY29tL2EvQUVkRlRwNkxQdGRLNk03c0FXN3lMdVVxVzhxaEVWU0VVeEoxRGMzOXlFTVY9czk2LWMiLCJlbWFpbCI6ImNvc3RhbnRpbi5naXVsaW9kb3JpQHN0dWRlbnRpLnVuaWNhbS5pdCIsImVtYWlsX3ZlcmlmaWVkIjp0cnVlLCJmdWxsX25hbWUiOiJDT1NUQU5USU5PIEdJVUxJT0RPUkkiLCJpc3MiOiJodHRwczovL3d3dy5nb29nbGVhcGlzLmNvbS91c2VyaW5mby92Mi9tZSIsIm5hbWUiOiJDT1NUQU5USU5PIEdJVUxJT0RPUkkiLCJwaWN0dXJlIjoiaHR0cHM6Ly9saDMuZ29vZ2xldXNlcmNvbnRlbnQuY29tL2EvQUVkRlRwNkxQdGRLNk03c0FXN3lMdVVxVzhxaEVWU0VVeEoxRGMzOXlFTVY9czk2LWMiLCJwcm92aWRlcl9pZCI6IjExNzkyODM4NDA5OTIwNjE4NTUyMCIsInN1YiI6IjExNzkyODM4NDA5OTIwNjE4NTUyMCJ9LCJyb2xlIjoiYXV0aGVudGljYXRlZCIsImFhbCI6ImFhbDEiLCJhbXIiOlt7Im1ldGhvZCI6Im9hdXRoIiwidGltZXN0YW1wIjoxNjc0NjAzMzM0fV0sInNlc3Npb25faWQiOiI2MDg4MTQ2MS03ZDQ1LTRjOTAtOTRkOC01NzMyOTQ4N2I4M2UifQ.vchb6QdCh-VAZDCaRbR69FC3BO3grW8Rz_2VpZIzRic","expires_in":3600,"expires_at":1674606937,"refresh_token":"s8A1yHAOxtZcU1Tayxk0Ig","token_type":"bearer","user":{"id":"67f6207e-feca-4b35-b12f-06ca81d80cf1","aud":"authenticated","role":"authenticated","email":"costantin.giuliodori@studenti.unicam.it","email_confirmed_at":"2023-01-24T23:35:34.151175Z","phone":"","confirmed_at":"2023-01-24T23:35:34.151175Z","last_sign_in_at":"2023-01-24T23:35:34.153124Z","app_metadata":{"provider":"google","providers":["google"]},"user_metadata":{"avatar_url":"https://lh3.googleusercontent.com/a/AEdFTp6LPtdK6M7sAW7yLuUqW8qhEVSEUxJ1Dc39yEMV=s96-c","email":"costantin.giuliodori@studenti.unicam.it","email_verified":true,"full_name":"COSTANTINO GIULIODORI","iss":"https://www.googleapis.com/userinfo/v2/me","name":"COSTANTINO GIULIODORI","picture":"https://lh3.googleusercontent.com/a/AEdFTp6LPtdK6M7sAW7yLuUqW8qhEVSEUxJ1Dc39yEMV=s96-c","provider_id":"117928384099206185520","sub":"117928384099206185520"},"identities":[{"id":"117928384099206185520","user_id":"67f6207e-feca-4b35-b12f-06ca81d80cf1","identity_data":{"avatar_url":"https://lh3.googleusercontent.com/a/AEdFTp6LPtdK6M7sAW7yLuUqW8qhEVSEUxJ1Dc39yEMV=s96-c","email":"costantin.giuliodori@studenti.unicam.it","email_verified":true,"full_name":"COSTANTINO GIULIODORI","iss":"https://www.googleapis.com/userinfo/v2/me","name":"COSTANTINO GIULIODORI","picture":"https://lh3.googleusercontent.com/a/AEdFTp6LPtdK6M7sAW7yLuUqW8qhEVSEUxJ1Dc39yEMV=s96-c","provider_id":"117928384099206185520","sub":"117928384099206185520"},"provider":"google","last_sign_in_at":"2023-01-24T23:35:34.139467Z","created_at":"2023-01-24T23:35:34.139515Z","updated_at":"2023-01-24T23:35:34.139515Z"}],"created_at":"2023-01-24T23:35:34.129419Z","updated_at":"2023-01-24T23:35:34.162094Z"}},"api_url":"http://localhost:54321/rest/v1/"}"""
  in
  Test.test "caricamento dei flags comprendenti il viewer in un oggetto json" <|
    \_ ->
      let
        -- decoder = (Decode.field "viewer" Decode.string)
        decoder = (Decode.field "viewer" Api.viewerDecoder)
      in
      -- Decode.decodeString decoder flags
      -- |> Result.andThen (Decode.decodeString Api.viewerDecoder)
      Decode.decodeString decoder flags
      |> testErr "Failed to decode a valid `viewer` flag"

-- viewerFlagTestAsString : Test.Test
-- viewerFlagTestAsString = 
--   let
--     flags = """
--     {"viewer":"{\"provider_token\":\"ya29.a0AVvZVsoKIpyyw7DTbkwri01BtN62Ngh514afTGa5z_vd_WOp6BRPgPlN0hR6U0t_i6vEuTuTscFOA7RFYwz0yk0dt1bTn0wGJ24kvDT7-HVSBSp5LUp9oon3fe0IvBk2Tj4u-oeaWd4nlm9UHCHkXZNGlqXZsdMaCgYKAQASARASFQGbdwaIPiRe0h_Kz4OpNV5teXC1vQ0166\",\"provider_refresh_token\":null,\"access_token\":\"eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhdWQiOiJhdXRoZW50aWNhdGVkIiwiZXhwIjoxNjc0NjAyNTE5LCJzdWIiOiIwMjQyZjY3YS01ZDk1LTQ3ZTYtOGU3Yi02ZTY5NGQ2M2M3MmUiLCJlbWFpbCI6ImNvc3RhbnRpbi5naXVsaW9kb3JpQHN0dWRlbnRpLnVuaWNhbS5pdCIsInBob25lIjoiIiwiYXBwX21ldGFkYXRhIjp7InByb3ZpZGVyIjoiZ29vZ2xlIiwicHJvdmlkZXJzIjpbImdvb2dsZSJdfSwidXNlcl9tZXRhZGF0YSI6eyJhdmF0YXJfdXJsIjoiaHR0cHM6Ly9saDMuZ29vZ2xldXNlcmNvbnRlbnQuY29tL2EvQUVkRlRwNkxQdGRLNk03c0FXN3lMdVVxVzhxaEVWU0VVeEoxRGMzOXlFTVY9czk2LWMiLCJlbWFpbCI6ImNvc3RhbnRpbi5naXVsaW9kb3JpQHN0dWRlbnRpLnVuaWNhbS5pdCIsImVtYWlsX3ZlcmlmaWVkIjp0cnVlLCJmdWxsX25hbWUiOiJDT1NUQU5USU5PIEdJVUxJT0RPUkkiLCJpc3MiOiJodHRwczovL3d3dy5nb29nbGVhcGlzLmNvbS91c2VyaW5mby92Mi9tZSIsIm5hbWUiOiJDT1NUQU5USU5PIEdJVUxJT0RPUkkiLCJwaWN0dXJlIjoiaHR0cHM6Ly9saDMuZ29vZ2xldXNlcmNvbnRlbnQuY29tL2EvQUVkRlRwNkxQdGRLNk03c0FXN3lMdVVxVzhxaEVWU0VVeEoxRGMzOXlFTVY9czk2LWMiLCJwcm92aWRlcl9pZCI6IjExNzkyODM4NDA5OTIwNjE4NTUyMCIsInN1YiI6IjExNzkyODM4NDA5OTIwNjE4NTUyMCJ9LCJyb2xlIjoiYXV0aGVudGljYXRlZCIsImFhbCI6ImFhbDEiLCJhbXIiOlt7Im1ldGhvZCI6Im9hdXRoIiwidGltZXN0YW1wIjoxNjc0NTk4OTE5fV0sInNlc3Npb25faWQiOiJmNDdjYmJkMC03NDVkLTQwNTQtODY0Ny1jMzcxY2E4ZmI2OTIifQ.9O6Eev138b4C65eu7luVVDG56zcX00EyACqprfxYVIY\",\"expires_in\":3600,\"expires_at\":1674602523,\"refresh_token\":\"bBIzfKBB-uqMWkPS_WryyA\",\"token_type\":\"bearer\",\"user\":{\"id\":\"0242f67a-5d95-47e6-8e7b-6e694d63c72e\",\"aud\":\"authenticated\",\"role\":\"authenticated\",\"email\":\"costantin.giuliodori@studenti.unicam.it\",\"email_confirmed_at\":\"2023-01-24T22:21:59.917394Z\",\"phone\":\"\",\"confirmed_at\":\"2023-01-24T22:21:59.917394Z\",\"last_sign_in_at\":\"2023-01-24T22:21:59.918297Z\",\"app_metadata\":{\"provider\":\"google\",\"providers\":[\"google\"]},\"user_metadata\":{\"avatar_url\":\"https://lh3.googleusercontent.com/a/AEdFTp6LPtdK6M7sAW7yLuUqW8qhEVSEUxJ1Dc39yEMV=s96-c\",\"email\":\"costantin.giuliodori@studenti.unicam.it\",\"email_verified\":true,\"full_name\":\"COSTANTINO GIULIODORI\",\"iss\":\"https://www.googleapis.com/userinfo/v2/me\",\"name\":\"COSTANTINO GIULIODORI\",\"picture\":\"https://lh3.googleusercontent.com/a/AEdFTp6LPtdK6M7sAW7yLuUqW8qhEVSEUxJ1Dc39yEMV=s96-c\",\"provider_id\":\"117928384099206185520\",\"sub\":\"117928384099206185520\"},\"identities\":[{\"id\":\"117928384099206185520\",\"user_id\":\"0242f67a-5d95-47e6-8e7b-6e694d63c72e\",\"identity_data\":{\"avatar_url\":\"https://lh3.googleusercontent.com/a/AEdFTp6LPtdK6M7sAW7yLuUqW8qhEVSEUxJ1Dc39yEMV=s96-c\",\"email\":\"costantin.giuliodori@studenti.unicam.it\",\"email_verified\":true,\"full_name\":\"COSTANTINO GIULIODORI\",\"iss\":\"https://www.googleapis.com/userinfo/v2/me\",\"name\":\"COSTANTINO GIULIODORI\",\"picture\":\"https://lh3.googleusercontent.com/a/AEdFTp6LPtdK6M7sAW7yLuUqW8qhEVSEUxJ1Dc39yEMV=s96-c\",\"provider_id\":\"117928384099206185520\",\"sub\":\"117928384099206185520\"},\"provider\":\"google\",\"last_sign_in_at\":\"2023-01-24T22:21:59.911371Z\",\"created_at\":\"2023-01-24T22:21:59.911424Z\",\"updated_at\":\"2023-01-24T22:21:59.911424Z\"}],\"created_at\":\"2023-01-24T22:21:59.90326Z\",\"updated_at\":\"2023-01-24T22:21:59.924121Z\"}}","api_url":"http://localhost:54321/rest/v1/"}
--     """

--   in
--   Test.test "caricamento dei flags comprendenti il viewer in un oggetto stringa json" <|
--     \_ ->
--       Decode.decodeString (Decode.field "viewer" Decode.string) flags
--       |> Result.andThen (Decode.decodeString Api.viewerDecoder)
--       |> testErr "Failed to decode a valid `viewer` string object"