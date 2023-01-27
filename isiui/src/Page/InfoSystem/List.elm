module Page.InfoSystem.List exposing 
  ( Model
  , Msg
  , init, update, view, subscriptions)

import Html.Events exposing (onClick)

import Http

import Html exposing (Html, a, button, div, li, nav, p, span, text, ul,h3,hr)
import Html.Attributes as HAttr exposing (class,  href, style, attribute)
import Html.Events exposing (onClick)
import Utils.UI

import Json.Decode as Decode
import Data.InfoSysSummary exposing (InfoSysId, decoder)
import RemoteData exposing (WebData)
import RemoteData.Http exposing (defaultConfig)
import Route exposing (Route)
import Data.InfoSysSummary as InfoSysSummary exposing (InfoSysSummary)
import Api exposing (apiConfig)
import Session.Session as Session
import Data.BasePageData as BasePageData
import Url
import Email
import Postgrest.Queries as Q


type alias DT = List InfoSysSummary.InfoSysSummary

type alias Model =
    BasePageData.BaseDataModel DT


type Msg
    = FetchInfosystems
    | InfosysReceived (WebData DT)
    


init : Session.Model -> ( Model, Cmd Msg )
init session =
  let 
    (model, _ ) = BasePageData.init session
  in
    ( {model | data = RemoteData.Loading}, fetchIS session )





fetchIS : Session.Model -> Cmd Msg
fetchIS session =
  let
    urlStr = Session.getApi session |> Url.toString
  in
    RemoteData.Http.getWithConfig (apiConfig session.session)
      (urlStr ++ "info_system" ++ "?" ++ listQry)
      InfosysReceived (Data.InfoSysSummary.decoder |> Decode.list)

    -- Http.get
    --     { url = "http://localhost:5019/posts/"
    --     , expect =
    --         postsDecoder
    --             |> Http.expectJson (RemoteData.fromResult >> PostsReceived)
    --     }

listQry : String
listQry =
  [ Q.select 
    [ Q.attribute "id"
    , Q.attribute "name"
    , Q.attribute "description"
    , Q.attribute "finality"
    , Q.resourceWithParams "resp:address_book!resp_email"
      [] (Q.attributes [ "fullname", "email", "legal_structure_name"])
    ]
  ] 
  |> Q.toQueryString
  |> Debug.log "querystring: " 


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        FetchInfosystems ->
            ( { model | data = RemoteData.Loading }
            , fetchIS model.session
            )

        InfosysReceived data ->
            ( { model | data = data }, Cmd.none )
        




-- VIEWS


view : Model -> Html Msg
view model =
    div 
      [class "container mb-5 mt-5 pt-5"]
      ( -- List.append (List.map Problem.viewProblems model.problems)
        Utils.UI.viewRemoteData (List.singleton << viewInfoSystems) model.data 
      
      )



viewInfoSystems : DT ->  Html Msg 
viewInfoSystems data = 
  div [ class "row" ] (List.map (viewSingleInfoSys True) data )

viewSingleInfoSys : Bool -> InfoSysSummary.InfoSysSummary ->  Html Msg 
viewSingleInfoSys canEdit data  = 
    div
        [ class "col-12 col-lg-6"
        ]
        [             {-start card-}
        div
            [ class "card-wrapper card-space"
            ]
            [ div
                [ class "card card-bg card-big border-bottom-card"
                ]
                [ if canEdit then
                    div
                      [ class "etichetta"
                      ]
                      [ Utils.UI.getIcon "it-pencil" []                    
                      , a [ Route.href (Route.ISEdit data.id)]
                          [ text "Modifica" ]
                      , span -- per l'accessibilita' tramite screen reader
                        [ class "visually-hidden" ]
                        [ text ("modifica il sistema informativo " ++ data.name) ]
                      ]
                  else
                    div [ class "etichetta"] []
                ------- 
                , div
                    [ class "card-body"
                    ]
                    [ h3
                          [ class "card-title h5 no_toc" ]
                          [ (InfoSysSummary.idToString data.id)
                              ++ "  -  " ++ data.name 
                            |> text
                          ]
                      , p
                          [ class "card-text" ]
                          [ text data.description ]
                          
                      
                    ]
                ------
                , div [ class "id-card-footer"]
                  [ span
                      [ class "card-signature" ]
                      [ text  data.respName ]
                  , p [ class "card-signature"]
                      [ text data.respStructure]
                    
                  , a
                      [ Route.href (Route.ISDetails data.id)
                      , class "read-more"
                      ]
                      [ span 
                          [ class "text"] 
                          [ text "Leggi di più" ]
                      , span -- per l'accessibilita' tramite screen reader
                          [ class "visually-hidden" ]
                          [ text ("vai al dettaglio del sistema informativo " ++ data.name) ]
                      , Utils.UI.getIcon "it-arrow-right" []                            
                      ]
                  ]
                ]
            ]
        {-end card-}
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