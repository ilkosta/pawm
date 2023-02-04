module Data.Bookmark exposing (..)

import Data.InfoSysSummary as ISS

import Json.Decode as Decode 
import Json.Decode.Pipeline as JsonPL
import Utils.Email exposing (..)
import Email
import Utils.Url exposing (..)
import Json.Encode as Encode

type alias Bookmark = 
  { id : ISS.InfoSysId
  , email : Email.Email
  }

econder : Bookmark -> Encode.Value
econder b =
  Encode.object
    [ ("infosys_id", Encode.int <| ISS.idToInt b.id)
    , ("email", Encode.string <| Email.toString b.email)
    ]

decoder : Decode.Decoder Bookmark
decoder =
  Decode.succeed Bookmark
    |> JsonPL.required "infosys_id" ISS.idDecoder
    |> JsonPL.required "email" emailDecoder

