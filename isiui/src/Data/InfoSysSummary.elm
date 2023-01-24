module Data.InfoSysSummary exposing 
  ( InfoSysId
  , idToString
  , idParser
  , idDecoder
  , idFromInt
  , idToInt
  , InfoSysSummary
  , decoder
  )

import Json.Decode as Decode exposing (int,string,Decoder)
import Json.Decode.Pipeline as JsonPL
import Url.Parser exposing (Parser,custom)

-- opaque type (https://elmprogramming.com/commands.html#opaque-type) 
-- to hide the implementation details
type InfoSysId = InfoSysId Int

idDecoder : Decoder InfoSysId
idDecoder =
    Decode.map InfoSysId int

idToInt : InfoSysId -> Int
idToInt (InfoSysId id) = id 

idToString : InfoSysId -> String
idToString (InfoSysId id) =
    String.fromInt id    

idParser : Parser (InfoSysId -> a) a
idParser =
  custom "infosystem identifier" <|
        \isId ->
            Maybe.map InfoSysId (String.toInt isId)

idFromInt : Int -> InfoSysId
idFromInt = InfoSysId

type alias InfoSysSummary = 
  { id : InfoSysId
  , name : String
  , description : String
  , finality : String
  }

decoder = 
  Decode.succeed InfoSysSummary
    |> JsonPL.required "id" idDecoder
    |> JsonPL.required "name" string
    |> JsonPL.required "description" string
    |> JsonPL.optional "finality" string "---"

