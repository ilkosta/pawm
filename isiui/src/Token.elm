module Token exposing (Token,decoder,fromJson,empty,isValid)

import Time
import Json.Decode as Json
import Json.Decode.Pipeline as JsonPL
import Json.Decode.Extra exposing (iso8601,posix)

decoder : Json.Decoder Token
decoder =
  Json.succeed Token
  |> JsonPL.requiredAt  ["currentSession","access_token"] Json.string
  |> JsonPL.requiredAt  ["currentSession","expires_in"] Json.int
  |> JsonPL.requiredAt  ["currentSession","expires_at"] posix 
  |> JsonPL.requiredAt  ["currentSession","user","created_at"] iso8601
  |> JsonPL.requiredAt  ["currentSession","user","updated_at"] iso8601
  |> JsonPL.requiredAt  ["currentSession","refresh_token"] Json.string
  |> JsonPL.requiredAt  ["currentSession", "user", "id"] Json.string
  |> JsonPL.requiredAt  ["currentSession", "user", "user_metadata" , "full_name"] Json.string
  |> JsonPL.requiredAt  ["currentSession", "user", "email"] Json.string
  |> JsonPL.requiredAt  ["currentSession", "user", "role"] Json.string

  
type alias Token = 
  { access_token: String
  , expire_in: Int
  , expire_at: Time.Posix 
  , created_at: Time.Posix
  , updated_at: Time.Posix
  , refresh_token: String
  -- user info
  , user_id: String
  , full_name: String
  , user_email: String
  , user_role: String
  }

empty : Token
empty = 
  { access_token = ""
  , expire_in = -1
  , expire_at = Time.millisToPosix 0 
  , created_at = Time.millisToPosix 0
  , updated_at = Time.millisToPosix 0
  , refresh_token = ""
  -- user info
  , user_id = ""
  , full_name = ""
  , user_email = ""
  , user_role  = ""
  }

fromJson : Json.Value -> Token
fromJson value =
  value
  |> Json.decodeValue decoder
  |> Result.withDefault empty

isValid : Token -> Bool
isValid t = (not << String.isEmpty << .user_id) t

