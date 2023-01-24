module TokenDecoding exposing (suite)


import Json.Decode exposing (decodeString)
import Token
import Test
import Expect
import Fuzz exposing (Fuzzer, int, list, string)



-- import test

suite : Test.Test
suite =
  Test.describe "decodifica del token" [validTokenDecoding]
  -- Test.test "prova" <| \_ -> Expect.pass

validTokenDecoding : Test.Test
validTokenDecoding = 
  let
    validToken = """
    {
      "currentSession": {
        "provider_token": "ya29.a0Aa4xrXORXI_i7IWELWvEQuy27LObNJmYKaJL8SQT1qWOnPxJdGpENVkU6YJtEiWlAsxVLWYWU1Oa0Zs86vN8WOC8bgtKUSN3R0hrxSiL3sPNkIJjts6yzapFnePG06pd3c9kHTtWmYZrBBpYkMw9MRI5KumBUAaCgYKATASAQ4SFQEjDvL9fgp-z91ZtaaMukbqCgZ-Ng0165",
        "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhdWQiOiJhdXRoZW50aWNhdGVkIiwiZXhwIjoxNjY2NTE3NTg5LCJzdWIiOiIwNGJmNDFmMi0wNTA4LTQyM2MtYjQxOC0yYjIwMjRhYzMzNWUiLCJlbWFpbCI6ImNvc3RhbnRpbi5naXVsaW9kb3JpQHN0dWRlbnRpLnVuaWNhbS5pdCIsInBob25lIjoiIiwiYXBwX21ldGFkYXRhIjp7InByb3ZpZGVyIjoiZ29vZ2xlIiwicHJvdmlkZXJzIjpbImdvb2dsZSJdfSwidXNlcl9tZXRhZGF0YSI6eyJhdmF0YXJfdXJsIjoiaHR0cHM6Ly9saDMuZ29vZ2xldXNlcmNvbnRlbnQuY29tL2EvQUxtNXd1M211NXFZSHVhbzZpZDg0bF9rVWZxYmJETGRFcWNGYk1NN2VWTlA9czk2LWMiLCJlbWFpbCI6ImNvc3RhbnRpbi5naXVsaW9kb3JpQHN0dWRlbnRpLnVuaWNhbS5pdCIsImVtYWlsX3ZlcmlmaWVkIjp0cnVlLCJmdWxsX25hbWUiOiJDT1NUQU5USU5PIEdJVUxJT0RPUkkiLCJpc3MiOiJodHRwczovL3d3dy5nb29nbGVhcGlzLmNvbS91c2VyaW5mby92Mi9tZSIsIm5hbWUiOiJDT1NUQU5USU5PIEdJVUxJT0RPUkkiLCJwaWN0dXJlIjoiaHR0cHM6Ly9saDMuZ29vZ2xldXNlcmNvbnRlbnQuY29tL2EvQUxtNXd1M211NXFZSHVhbzZpZDg0bF9rVWZxYmJETGRFcWNGYk1NN2VWTlA9czk2LWMiLCJwcm92aWRlcl9pZCI6IjExNzkyODM4NDA5OTIwNjE4NTUyMCIsInN1YiI6IjExNzkyODM4NDA5OTIwNjE4NTUyMCJ9LCJyb2xlIjoiYXV0aGVudGljYXRlZCIsInNlc3Npb25faWQiOiI2YmIxZDhkZS1mYWVjLTRiZGQtYmFhZS0yNDllY2U3NThmMmQifQ.zRI7oxpzC1GifP_IqBDQLLH0aRwMfIt02h76_nEu6Ew",
        "expires_in": 3600,
        "expires_at": 1666517591,
        "refresh_token": "PsNUfSZAnqm6Ib94VjrfZg",
        "token_type": "bearer",
        "user": {
          "id": "04bf41f2-0508-423c-b418-2b2024ac335e",
          "aud": "authenticated",
          "role": "authenticated",
          "email": "costantin.giuliodori@studenti.unicam.it",
          "email_confirmed_at": "2022-10-22T06:06:33.964415Z",
          "phone": "",
          "confirmed_at": "2022-10-22T06:06:33.964415Z",
          "last_sign_in_at": "2022-10-23T08:33:09.279406Z",
          "app_metadata": {
            "provider": "google",
            "providers": [
              "google"
            ]
          },
          "user_metadata": {
            "avatar_url": "https://lh3.googleusercontent.com/a/ALm5wu3mu5qYHuao6id84l_kUfqbbDLdEqcFbMM7eVNP=s96-c",
            "email": "costantin.giuliodori@studenti.unicam.it",
            "email_verified": true,
            "full_name": "COSTANTINO GIULIODORI",
            "iss": "https://www.googleapis.com/userinfo/v2/me",
            "name": "COSTANTINO GIULIODORI",
            "picture": "https://lh3.googleusercontent.com/a/ALm5wu3mu5qYHuao6id84l_kUfqbbDLdEqcFbMM7eVNP=s96-c",
            "provider_id": "117928384099206185520",
            "sub": "117928384099206185520"
          },
          "identities": [
            {
              "id": "117928384099206185520",
              "user_id": "04bf41f2-0508-423c-b418-2b2024ac335e",
              "identity_data": {
                "avatar_url": "https://lh3.googleusercontent.com/a/ALm5wu3mu5qYHuao6id84l_kUfqbbDLdEqcFbMM7eVNP=s96-c",
                "email": "costantin.giuliodori@studenti.unicam.it",
                "email_verified": true,
                "full_name": "COSTANTINO GIULIODORI",
                "iss": "https://www.googleapis.com/userinfo/v2/me",
                "name": "COSTANTINO GIULIODORI",
                "picture": "https://lh3.googleusercontent.com/a/ALm5wu3mu5qYHuao6id84l_kUfqbbDLdEqcFbMM7eVNP=s96-c",
                "provider_id": "117928384099206185520",
                "sub": "117928384099206185520"
              },
              "provider": "google",
              "last_sign_in_at": "2022-10-22T06:06:33.959171Z",
              "created_at": "2022-10-22T06:06:33.959245Z",
              "updated_at": "2022-10-23T08:33:09.275512Z"
            }
          ],
          "created_at": "2022-10-22T06:06:33.952427Z",
          "updated_at": "2022-10-23T08:33:09.283984Z"
        }
      },
      "expiresAt": 1666517591
    }
    """
  in
    Test.test "decodifica di un token valido" <| 
      \_ -> case decodeString Token.decoder validToken of
          Ok _ ->
            Expect.pass

          Err _ ->
            Expect.fail "Failed to decode a valid token"