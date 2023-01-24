module InfoSysSummary exposing 
  ( InfoSysId
  , idToString
  , idParser
  , InfoSysSummary
  , decoder
  )

import Json.Decode as Decode exposing (int,string,Decoder)
import Json.Decode.Pipeline as JsonPL
import Url.Parser exposing (Parser, custom)

-- opaque type (https://elmprogramming.com/commands.html#opaque-type) 
-- to hide the implementation details
type InfoSysId = InfoSysId Int

idDecoder : Decoder InfoSysId
idDecoder =
    Decode.map InfoSysId int

idToString : InfoSysId -> String
idToString (InfoSysId id) =
    String.fromInt id    

idParser : Parser (InfoSysId -> a) a
idParser =
  custom "infosystem identifier" <|
        \isId ->
            Maybe.map InfoSysId (String.toInt isId)

type alias InfoSysSummary = 
  { id : InfoSysId
  , name : String
  , description : String
  , finality : String
  }

decoder : Decoder InfoSysSummary
decoder = 
  Decode.succeed InfoSysSummary
    |> JsonPL.required "id" idDecoder
    |> JsonPL.required "name" string
    |> JsonPL.required "description" string
    |> JsonPL.optional "finality" string "---"

