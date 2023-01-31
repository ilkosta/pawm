module Data.UO exposing (..)

import Json.Decode as Decode exposing (int,string,Decoder)
import Json.Decode.Pipeline as JsonPL

type UOCod = UOCod String

codToString (UOCod s) = s

codDecoder : Decoder UOCod
codDecoder =
    Decode.map UOCod string

type alias UO = 
  { id  : Int
  , cod : UOCod
  , description : String
  }

decoder =
  Decode.succeed UO
  |> JsonPL.required "id" Decode.int
  |> JsonPL.required "coddesc" codDecoder
  |> JsonPL.required "description" Decode.string