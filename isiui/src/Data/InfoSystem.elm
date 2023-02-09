module Data.InfoSystem exposing 
  ( InfoSystem
  , decoder
  , encoder
  )

import Data.InfoSysSummary as ISS
import Url
import Json.Decode as Decode exposing (string)
import Json.Decode.Pipeline as JsonPL
import Utils.Email exposing (..)
import Email
import Utils.Url exposing (..)
import Json.Decode exposing (int)
import Json.Encode as Encode

type alias InfoSystem = 
  { id : Maybe ISS.InfoSysId
  , name : String
  , description : String
  , finality : String
  , uo : Int
  , resp : Email.Email
  , respInf : Maybe Email.Email
  , passPrj : Url.Url
  }





decoder =
  Decode.succeed InfoSystem
    |> JsonPL.required "id" (Decode.nullable ISS.idDecoder)
    |> JsonPL.required "name" string
    |> JsonPL.required "description" string
    |> JsonPL.optional "finality" string "---"
    |> JsonPL.required "uo_id" int
    |> JsonPL.required "resp_email" emailDecoder
    |> JsonPL.required "resp_inf_email" (Decode.nullable emailDecoder)
    |> JsonPL.optional "pass_url" urlDecoder emptyUrl



encoder : InfoSystem -> Encode.Value
encoder i =
  let
    emailEnc = (Email.toString >> Encode.string)
    urlEnc = (Url.toString >> Encode.string) 
    sysIdEnc = (ISS.idToInt >> Encode.int)
    maybeEnc enc f = Maybe.map enc f |> Maybe.withDefault Encode.null
    optional f = 
      if String.isEmpty f
      then Encode.null
      else Encode.string f
  in
  Encode.object <|
      [ ( "name", Encode.string i.name )
      , ( "description", Encode.string i.description )
      , ( "finality", optional i.finality )
      , ( "uo_id", Encode.int i.uo )
      , ( "pass_url", urlEnc i.passPrj )
      , ( "resp_email", emailEnc i.resp )
      , ( "resp_inf_email", maybeEnc emailEnc i.respInf )
      ]    
