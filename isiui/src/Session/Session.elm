module Session.Session exposing 
  ( Model
  , Session, ApiUrl, getApi, apiUrlDecoder
  , cred, fromViewer, navKey, viewer)

import Browser.Navigation as Nav
import Session.Viewer as Viewer exposing (Viewer)
import Session.Cred exposing (Cred)
import Url
import Utils.Url

import Json.Decode as Decode


-- TYPES

-- opaque type to prevent manipulation and catch any type assignment errors
type ApiUrl = ApiUrl Url.Url

type alias Model = 
  { apiUrl : ApiUrl
  , session : Session
  }

getApi : { apiUrl | apiUrl : ApiUrl } -> Url.Url
getApi {apiUrl} = 
  let
    (ApiUrl url) = apiUrl
  in
    url
    
apiUrlDecoder = 
  Decode.field "api_url" Utils.Url.urlDecoder

type Session
    = LoggedIn Nav.Key Viewer
    | Guest Nav.Key


fromViewer : Url.Url -> Nav.Key -> Maybe Viewer -> Model
fromViewer apiUrl key maybeViewer =
  let
    session = 
      -- It's stored in localStorage as a JSON String;
      -- first decode the Value as a String, then
      -- decode that String as JSON.
      case maybeViewer of
          Just viewerVal ->
              LoggedIn key viewerVal

          Nothing ->
              Guest key
    
  in
    { apiUrl = ApiUrl apiUrl , session = session }


-- INFO

{-| return the Viewer associated withe the Session -}
viewer : Session -> Maybe Viewer
viewer session =
    case session of
        LoggedIn _ val ->
            Just val

        Guest _ ->
            Nothing

{-| return the Cred associated withe the Session -}
cred : Session -> Maybe Cred
cred session =
    case session of
        LoggedIn _ val ->
            Just (Viewer.cred val)

        Guest _ ->
            Nothing

{-| return the Nav.Key associated withe the Session -}
navKey : Session -> Nav.Key
navKey session =
    case session of
        LoggedIn key _ ->
            key

        Guest key ->
            key

