module Data.Person exposing (..)


import Utils.Email
import Email
import Json.Decode as Decode exposing (int,string,Decoder)
import Json.Decode.Pipeline as JsonPL


type alias Person =
  { fullname : String
  , role : String
  , uo : String
  , email : Email.Email
  }

emptyPerson =
  { fullname = "-----"
  , role = ""
  , uo = "-----"
  , email = Utils.Email.emptyEmail
  }

type alias People = List Person  

decoder =
  Decode.succeed Person
  |> JsonPL.required "fullname" Decode.string
  |> JsonPL.required "pa_role" Decode.string
  |> JsonPL.required "legal_structure_name" Decode.string
  |> JsonPL.required "email" Utils.Email.emailDecoder
