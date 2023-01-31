port module Api exposing
    ( apiConfig
    , login
    , logout
    , qryWithRepresentationConfig
    , sessionChanges
    , viewerDecoder
    , apiConfigToRequestConfig
    , apiSingleResult
    -- , uoRemoteSearchAttrs
    -- , peopleRemoteSearchAttrs
    -- , loadPeople
    )

import Browser.Navigation as Nav
import Http exposing (header)
import Json.Decode as Decode
import RemoteData.Http exposing (defaultConfig)
import Session.Cred as Cred exposing (Cred)
import Session.Session as Session exposing (Session)
import Session.Viewer as Viewer exposing (Viewer)
import Dict
import Html exposing (s)
import Data.Person
import Http exposing (Header)
import SingleSelectRemote
import Data.UO
import Postgrest.Queries as Q
import Url

apiConfigToRequestConfig : Dict.Dict String String -> RemoteData.Http.Config
apiConfigToRequestConfig conf =
  let
    headers = Dict.toList conf |> List.map (\(k,v) -> header k v)
  in
    { defaultConfig | headers = headers }


headerRemoteSearchAttrs : Session.Session -> List Header
headerRemoteSearchAttrs session = 
  apiConfig session
  |> Dict.toList 
  |> List.map (\(k,v) -> header k v)


-- type alias RemoteQueryAttrs a =
--   { headers : List Header
--   , url : String -> String
--   , optionDecoder : Decode.Decoder a
--   }
-- uoRemoteSearchAttrs : Session.Model -> RemoteQueryAttrs Data.UO.UO
-- uoRemoteSearchAttrs session =
--   let
--     ilike : String -> Q.Operator
--     ilike s = Q.ilike ("*" ++ s ++ "*")
--     searchUrl s = 
--       (Session.getApi session |> Url.toString) 
--       ++ "uo?" ++ 
--       ([ Q.attributes ["id","coddesc","description"] 
--         |> Q.select 
--       , Q.or 
--         [ Q.param "coddesc" (ilike s)
--         , Q.param "description" (ilike s)
--         ]
--       , Q.order [Q.asc "description"]
--       ] |> Q.toQueryString)
--   in
--   { headers = headerRemoteSearchAttrs session.session
--   , url = searchUrl
--   , optionDecoder = Data.UO.decoder
--   }    



-- peopleRemoteSearchAttrs : Session.Model -> RemoteQueryAttrs Data.Person.People
-- peopleRemoteSearchAttrs session =
--   let
--     ilike s = Q.ilike ("*" ++ s ++ "*")
--     searchUrl s = 
--       (Session.getApi session |> Url.toString) 
--       ++ "address_book?" ++ 
--       ([ Q.attributes ["fullname","pa_role","legal_structure_name","email"] 
--         |> Q.select 
--       , Q.param "fullname" (ilike s)
--       , Q.order [Q.asc "fullname"]
--       ] |> Q.toQueryString) |> Debug.log "preparo la query: "
--   in
--   { headers = headerRemoteSearchAttrs session.session
--   , url = searchUrl
--   , optionDecoder = Data.Person.decoder
--   }    



-- loadPeople : ( (Result Http.Error Data.Person.People) -> msg) -> Session.Model -> Cmd msg
-- loadPeople msg session =
--   Http.request 
--     { method = "GET"
--     , headers = headerRemoteSearchAttrs session.session
--     , url = 
--         (Session.getApi session |> Url.toString) 
--         ++ "address_book?" 
--         ++  ( [ Q.select <| Q.attributes ["fullname","pa_role","legal_structure_name","email"]
--               , Q.order [Q.asc "fullname" ]
--               ] |> Q.toQueryString
--             )
--     , body = Http.emptyBody
--     , expect = Http.expectJson msg (Decode.list Data.Person.decoder)
--     , timeout = Nothing
--     , tracker = Nothing
--     }

apiConfig : Session -> Dict.Dict String String
apiConfig session =
  let
    anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0"
    authKey =
      case Session.viewer session of
        Nothing -> anonKey
        Just viewer -> Viewer.token viewer
    
  in
    Dict.fromList 
      [ ("apikey", anonKey)
      , ("Authorization", "Bearer " ++ authKey)
      , ("Prefer", "count=estimated" ) -- https://postgrest.org/en/stable/api.html#estimated-count
      , ("Accept", "application/json")
      ]


apiSingleResult : Dict.Dict String String -> Dict.Dict String String
apiSingleResult conf =
  let 
    -- https://postgrest.org/en/stable/api.html#singular-or-plural
    f = Maybe.andThen (\_ -> Just "application/vnd.pgrst.object+json") 
  in
  Dict.update "Accept" f conf 
  

qryWithRepresentationConfig : Session -> RemoteData.Http.Config
qryWithRepresentationConfig session =
    let
        config =
            apiConfig session |> apiConfigToRequestConfig
    in
    { config
        | headers =
            header "Prefer" "return=representation" :: config.headers
    }



----- LocalStorage


{-| JS INTERACTION

Elm interact with a JavaScript library is very similar to how we interact
with an external service such as an HTTP server.
In both cases we tell the Elm runtime to perform an operation by sending a command.
When the operation is complete, the runtime sends a message back to our app.

[elm side effect mng](https://elmprogramming.com/images/chapter-5/5.5-side-effects/elm-runtime.svg)

some port annotations:

  - Elm doesn’t allow any code to pass through a port. All we can send is data
  - All ports defined in Elm app can be accessed through js by calling `app.ports`
  - `port` keyword automatically create a function, that can be used as a regular function
  - the return `Cmd msg` is for a command that doesn't send any messages back to the app:
    the Elm runtime send some data to Javascript

INCOMING PORTS:

  - take a function that map a value to a message
  - return a subscription to send a message to our app whenever the JavaScript code sends some data

-}
port onStoreChange : (Decode.Value -> msg) -> Sub msg


{-| OUTGOING PORTS

sending data to JS from Elm

  - for example from the view a message is sent to Elm Runtime
  - the Elm runtime forwards the message to the update function
  - the update call the port by running a command that doesn't send back any message
  - the command call a subscribed javascript function

-}
port storeCache : Maybe Decode.Value -> Cmd msg


port login : () -> Cmd msg


{-| event generated by js
-}
sessionChanges : (Session.Model -> msg) -> Session.Model -> Nav.Key -> Sub msg
sessionChanges toMsg session key =
    let
        apiUrl_ =
            Session.getApi session

        

        viewer =
            \v ->
                Decode.decodeValue viewerDecoder v
                    |> Result.toMaybe
                    |> Session.fromViewer apiUrl_ key
                    |> toMsg
    in
    onStoreChange viewer

viewerDecoder = 
              Decode.map2 (\a b -> a b) 
                Viewer.decoder Cred.decoder

logout : Cmd msg
logout =
    storeCache Nothing


