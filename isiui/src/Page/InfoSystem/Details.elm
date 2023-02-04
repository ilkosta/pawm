module Page.InfoSystem.Details exposing ( Model
  , Msg
  , init, update, view, subscriptions)

import Data.InfoSystem as InfoSystem
import Data.Person exposing (Person)
import Html.Events exposing (onClick)

import Svg.Attributes as SvgAttr
import Http

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Utils.UI as UI


import Json.Decode as Decode exposing (string)
import Json.Decode.Pipeline as JsonPL

import Data.Bookmark as Bookmark
import Data.Person as Person
import RemoteData exposing (WebData)
import RemoteData.Http
import Route 
import Data.InfoSysSummary as InfoSysSummary exposing (InfoSysId)
import Data.InfoSystem as InfoSystem
import Api exposing (apiConfig)
import Session.Session as Session
-- import Data.BasePageData as BasePageData
import Url
import Utils.Url exposing (emptyUrl,urlDecoder)
-- import Utils.Error.LoadingProblem  as Problem
import Postgrest.Queries as Q
import Email
import Html.Attributes exposing (placeholder)
import Html.Events exposing (onInput)

import Session.Viewer as Viewer

import List.Extra

type alias DT =  
  { id : InfoSysSummary.InfoSysId
  , name : String
  , description : String
  , finality : String
  , uo : String
  , resp : Person
  , respInf : Maybe Person
  , passPrj : Url.Url
  , authorized : Bool
  , observed : Bool
  }

dtDecoder : Decode.Decoder DT
dtDecoder = 
  let
    exists : List a -> Bool
    exists l =
      not <| List.isEmpty l
  in
  Decode.succeed DT
    |> JsonPL.required "id" InfoSysSummary.idDecoder
    |> JsonPL.required "name" string
    |> JsonPL.required "description" string
    |> JsonPL.optional "finality" string "---"
    |> JsonPL.requiredAt ["uo","description"] string
    |> JsonPL.required "resp" Person.decoder
    |> JsonPL.required "resp_inf" (Decode.nullable Person.decoder)
    |> JsonPL.optional "pass_url" urlDecoder emptyUrl
    |> JsonPL.required "authorizations" (Decode.map exists <| Decode.list ( Decode.field "email" string) )
    |> JsonPL.required "observers" (Decode.map exists <| Decode.list ( Decode.field "email" string) )
    


type alias Model =
  { data : WebData DT
  , session : Session.Model
  , error : Maybe String
  }

type Msg
    = ISReceived (WebData DT)
    | BookmarkMsg InfoSysSummary.InfoSysId
    | BookmarkedMsg (Result Http.Error Bookmark.Bookmark)

init : InfoSysId -> Session.Model -> ( Model, Cmd Msg )
init isId session =
  let 
    model = 
      { data = RemoteData.Loading
      , session = session
      , error = Nothing
      }
  in
  ( model , fetchIS isId model)


fetchIS : InfoSysId ->  {a | session : Session.Model} -> Cmd Msg
fetchIS isId {session} =
  let
    baseUrl = Session.getApi session |> Url.toString
    qry = 
      (Q.param "id" <| Q.eq <| Q.int <| InfoSysSummary.idToInt isId)
      :: (defaultQry session.session)
      |> Q.toQueryString 

    url = baseUrl ++ "info_system" ++ "?" ++ qry

    reqConfig = 
      apiConfig session.session
      |> Api.apiSingleResult 
      |> Api.apiConfigToRequestConfig
  in
    RemoteData.Http.getWithConfig reqConfig url
      ISReceived dtDecoder


defaultQry : Session.Session -> Q.Params
defaultQry session =
  let
    meParams =
      case Session.viewer session of
        Just viewer -> 
          Viewer.email viewer
          |> Email.toString
          |> Q.string
          |> Q.eq
          |> Q.param "email"
          |> List.singleton
        Nothing -> []
  in
  [ Q.select 
    [ Q.attribute "id"
    , Q.attribute "name"
    , Q.attribute "description"
    , Q.attribute "finality"
    , Q.attribute "pass_url"
    , Q.resourceWithParams "resp:address_book!resp_email"
      [] (Q.attributes [ "fullname", "email", "legal_structure_name","pa_role"])
    , Q.resourceWithParams "resp_inf:address_book!resp_inf_email"
      [] (Q.attributes [ "fullname", "email", "legal_structure_name","pa_role"])
      , Q.resourceWithParams "uo"
      [] (Q.attributes ["coddesc","description"])
    ----
    , Q.resourceWithParams "authorizations"
      meParams (Q.attributes [ "email"])
    , Q.resourceWithParams "observers"
      meParams (Q.attributes [ "email"])
    ]
  ]


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ISReceived data ->
            ( { model | data = data }, Cmd.none )

        BookmarkMsg id ->
              ( model, sendBookmark model id )

        BookmarkedMsg (Result.Ok _) -> 
          case model.data of
            RemoteData.Success is_ ->
              let
                is = {is_ | observed = not is_.observed }
              in
              ( {model | data = RemoteData.Success is}, Cmd.none)
            _ -> ( model, Cmd.none)
          

        BookmarkedMsg (Result.Err err) -> 
          ( { model | error = Just <| UI.buildErrorMessage err }
          , Cmd.none
          )



sendBookmark model id = 
  case model.data of
    RemoteData.Success d ->
      let
        bookmarked = d.observed
      in
        Api.sendBookmark BookmarkedMsg 
          model.session bookmarked id

    _ -> Cmd.none


view : Model -> Html Msg
view model =
    div 
      [class "container mb-5 mt-5 pt-5"]
      ( UI.viewRemoteData (List.singleton << (viewIS model)) model.data      
      )

viewIS : {m| session : Session.Model} -> DT ->  Html Msg 
viewIS {session} data =
    let 
        editHeader = 
          if Api.canEdit session.session data then
            [ div
              [ class "etichetta" ]
              [ UI.getIcon "it-pencil" []                    
              , a [ Route.href (Route.ISEdit data.id)]
                  [ text "Modifica" ]
              , span -- per l'accessibilita' tramite screen reader
                [ class "visually-hidden" ]
                [ text ("modifica il sistema informativo " ++ data.name) ]
              ]
            ]
          else
            []

        bookmarkIcon = 
          if data.observed
            then "it-star-full"
            else "it-star-outline"

        bookmark = 
          Maybe.map 
            (\_ -> 
              span  [ class "d-flex align-content-start flex-wrap" 
                    , onClick <| BookmarkMsg data.id 
                    ] 
                    [ UI.getIcon bookmarkIcon [SvgAttr.class "icon-primary"] ])
            (Session.viewer session.session)  
          |> Maybe.withDefault (span [] [])

        isTitle = (InfoSysSummary.idToString data.id)
                              ++ "  -  " ++ data.name 

        viewPerson : String -> Person -> List (Html Msg)
        viewPerson lbl person = 
          
            [ div [ class "col-sm-6"] 
              [ blockquote [ class "blockquote blockquote-card"]
                [ p [] [ strong [] [ text lbl]]
                , p [ ] 
                  [ a [ href <| "mailto:" ++ (Email.toString person.email) ] 
                    [ UI.getIcon "it-mail" [] ]
                  , text person.fullname 
                  ]
                , span [ ] [ text person.uo ]
                  , footer [ class "blockquote-footer" ]
                    [ small [ ] [ text person.role ] ]                  
                ]
              ]
            ]
          
       
    in
    div [ class  "row" ]
    [ div [ class "col-12 col-lg-12" ]
      [ div [ class "card-wrapper card-space"]
        [ div [class "card card-bg card-big", style "padding" "10px"]
          ( (bookmark :: editHeader) ++ 
            [ div [ class "card-body   text-start"]
              [ div [ class "row" ] 
                [ div [class "col-1"] 
                  [ div [ class "top-icon"] [ UI.getIcon "it-card" [] ] ]
                , div [class "col-11"] 
                  [ h3 [ class "card-title h5 "] [ text isTitle ] 
                  , p [ ] [ text data.description ]
                  ]
                ]
              
              , p [] [text data.uo]
              , p [ ] [ text data.finality ]

              , span [] 
                [ strong [] [ text "registrato su Pass"]
                , span [] [text " come "]
                , a [href (Url.toString data.passPrj)]
                  [ Url.toString data.passPrj
                    |> String.split "/"
                    |> List.Extra.last
                    |> Maybe.withDefault (InfoSysSummary.idToString data.id)
                    |> text
                  ]
                ]

              , div [ class "row"] 
                (( Maybe.withDefault [] <| 
                  Maybe.map (viewPerson "responsabile informatico") data.respInf
                )
                |> List.append ( viewPerson "responsabile" data.resp )
                )
              ]     
              
            ]
          )
        ]
      ]
    ]


{-| 
Subscriptions scope:

- listen to an event generated by a Javascript code
- encode the event to a message
- send the message to `update`

Subscriptions allow us to listen to external events such as incoming WebSocket messages, 
clock tick events, mouse/keyboard events, geolocation changes, 
and an output generated by a JavaScript library.

Subscription ask the Elm runtime to listen for the specified event 
and then send the corresponding message to update the model
-}

subscriptions : Model -> Sub Msg
subscriptions _ =
  Sub.none