port module Api exposing 
  ( apiConfig
  , qryWithRepresentationConfig
  , login, logout
  , sessionChanges
  , storageDecoder
  )

import Json.Decode as JD


import Http exposing (header)
import RemoteData.Http exposing (defaultConfig)


import Session.Cred as Cred exposing (Cred)
import Session.Session as Session exposing (Session)
import Session.Viewer exposing (Viewer)
import Browser.Navigation as Nav
import Session.Viewer as Viewer

apiConfig : Session -> RemoteData.Http.Config
apiConfig _ = 
  { defaultConfig 
  | headers = 
    [ header "apikey" "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24ifQ.625_WdcF3KHqz5amU0x2X5WWHP-OEs_4qj0ssLNHzTs"
    , header "Authorization" "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhdWQiOiJhdXRoZW50aWNhdGVkIiwiZXhwIjoxNjYzMDAyNDAwLCJzdWIiOiI3ZWYxODgyNS0xOGYwLTQ4NGYtOTJlMi03NTFiYWNhZjQ2MGQiLCJlbWFpbCI6ImNvc3RhbnRpbi5naXVsaW9kb3JpQHN0dWRlbnRpLnVuaWNhbS5pdCIsInBob25lIjoiIiwiYXBwX21ldGFkYXRhIjp7InByb3ZpZGVyIjoiZ29vZ2xlIiwicHJvdmlkZXJzIjpbImdvb2dsZSJdfSwidXNlcl9tZXRhZGF0YSI6eyJhdmF0YXJfdXJsIjoiaHR0cHM6Ly9saDMuZ29vZ2xldXNlcmNvbnRlbnQuY29tL2EvQUl0YnZtbDE1V25CS013LWlzN1EyTFVoZV9MMTJwSTZBRzZhVi00NkRnNDc9czk2LWMiLCJlbWFpbCI6ImNvc3RhbnRpbi5naXVsaW9kb3JpQHN0dWRlbnRpLnVuaWNhbS5pdCIsImVtYWlsX3ZlcmlmaWVkIjp0cnVlLCJmdWxsX25hbWUiOiJDT1NUQU5USU5PIEdJVUxJT0RPUkkiLCJpc3MiOiJodHRwczovL3d3dy5nb29nbGVhcGlzLmNvbS91c2VyaW5mby92Mi9tZSIsIm5hbWUiOiJDT1NUQU5USU5PIEdJVUxJT0RPUkkiLCJwaWN0dXJlIjoiaHR0cHM6Ly9saDMuZ29vZ2xldXNlcmNvbnRlbnQuY29tL2EvQUl0YnZtbDE1V25CS013LWlzN1EyTFVoZV9MMTJwSTZBRzZhVi00NkRnNDc9czk2LWMiLCJwcm92aWRlcl9pZCI6IjExNzkyODM4NDA5OTIwNjE4NTUyMCIsInN1YiI6IjExNzkyODM4NDA5OTIwNjE4NTUyMCJ9LCJyb2xlIjoiYXV0aGVudGljYXRlZCIsInNlc3Npb25faWQiOiIxMTM4YTEwMC0zMDU2LTQ2M2MtOTMyMS1kNTdlOWRiNWZhZDQifQ.AkSdJdUuLgJ_le9a_svb2OJZOkIk5HN08FVRnmX3brY"
    ]
  }

qryWithRepresentationConfig :  Session -> RemoteData.Http.Config
qryWithRepresentationConfig session = 
  let 
    config = apiConfig session
  in
  { config
  | headers = 
      (header "Prefer" "return=representation" ) :: config.headers
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

port onStoreChange : (JD.Value -> msg) -> Sub msg


{-| OUTGOING PORTS

sending data to JS from Elm 
- for example from the view a message is sent to Elm Runtime
- the Elm runtime forwards the message to the update function
- the update call the port by running a command that doesn't send back any message
- the command call a subscribed javascript function 
-}
port storeCache : Maybe JD.Value -> Cmd msg

port login : () -> Cmd msg


{-| event generated by js -}
sessionChanges : (Session -> msg) -> Session.Model -> Nav.Key -> Sub msg
sessionChanges toMsg session key =
  let
    apiUrl_ = Session.getApi session
    viewer = \v -> JD.decodeValue (storageDecoder Viewer.decoder) v 
                    |> Result.toMaybe
                    |> Session.fromViewer apiUrl_ key
                    |> .session
                    |> toMsg
  in
    onStoreChange viewer


storageDecoder : JD.Decoder (Cred -> viewer) -> JD.Decoder viewer
storageDecoder viewerDecoder =
    JD.field "viewer" <| decoderFromCred viewerDecoder        

{-| 
  hackinsh game... modify the decoding type of cred to fromCred
-}
decoderFromCred : JD.Decoder (Cred -> a) -> JD.Decoder a
decoderFromCred decoder =
    JD.map2 (\fromCred cred -> fromCred cred)
        decoder
        Cred.decoder


logout : Cmd msg
logout =
    storeCache Nothing
