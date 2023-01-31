module Route exposing (Route(..), parseUrl,href, pushUrl)

import Browser.Navigation as Nav

import Html exposing (Attribute)
import Html.Attributes

import Url exposing (Url)
import Url.Parser exposing (..)
import Data.InfoSysSummary as ISysSummary exposing (InfoSysId)



type Route
    = NotFound
    | Home
    | ISList
    | ISNew
    -- | ISDetails InfoSysId
    | ISEdit InfoSysId
    | ISDetails InfoSysId
    
    


parseUrl : Url -> Route
parseUrl url =
    case parse matchRoute url of
        Just route ->
            route

        Nothing ->
            NotFound


matchRoute : Parser (Route -> a) a
matchRoute =
    oneOf
        [ map Home top
        , map ISList (s "sistemi")
        , map ISNew (s "sistema" </> s "nuovo")
        -- , map ISDetails (s "sistemi" </> ISysSummary.idParser)
        , map ISEdit    (s "sistema" </> ISysSummary.idParser </> s "modifica")
        , map ISDetails (s "sistema" </> ISysSummary.idParser )
        ]


routeToPieces : Route -> List String
routeToPieces page =
    case page of
        Home ->
            []
        NotFound -> ["404"]

        -- Root ->
        --     []

        -- Login ->
        --   [ "login"]

        -- Logout ->
        --   [ "logout"]

        ISList ->
          ["sistemi"]

        ISNew -> [ "sistema", "nuovo"]

        ISEdit id ->
          ["sistema", ISysSummary.idToString id, "modifica"  ]
        
        ISDetails id -> 
          ["sistema", ISysSummary.idToString id ]
        -- Settings ->
        --     [ "settings" ]

        -- Profile username ->
        --     [ "profile", Username.toString username ]

----- VIEW Utils

href : Route -> Attribute msg
href targetRoute =
  routeToString targetRoute
  |> Html.Attributes.href        

-- INTERNAL fragment like a path
routeToString : Route -> String
routeToString page =
    "/" ++ String.join "/" (routeToPieces page)  

pushUrl : Route -> Nav.Key -> Cmd msg
pushUrl route navKey =
    routeToString route
        |> Nav.pushUrl navKey    