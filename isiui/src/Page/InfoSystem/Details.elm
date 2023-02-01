module Page.InfoSystem.Details exposing ( Model
  , Msg
  , init, update, view, subscriptions)

import Data.InfoSystem as InfoSystem
import Data.Person exposing (Person)
import Html.Events exposing (onClick)

import Dict

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Utils.UI as UI


import Json.Decode as Decode exposing (string)
import Json.Decode.Pipeline as JsonPL

import Data.InfoSysSummary
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
  }

dtDecoder : Decode.Decoder DT
dtDecoder = 
  Decode.succeed DT
    |> JsonPL.required "id" InfoSysSummary.idDecoder
    |> JsonPL.required "name" string
    |> JsonPL.required "description" string
    |> JsonPL.optional "finality" string "---"
    |> JsonPL.requiredAt ["uo","description"] string
    |> JsonPL.required "resp" Person.decoder
    |> JsonPL.required "resp_inf" (Decode.nullable Person.decoder)
    |> JsonPL.optional "pass_url" urlDecoder emptyUrl



type alias Model =
  { data : WebData DT
  , session : Session.Model
  }

type Msg
    = ISReceived (WebData DT)
    -- | FetchISMsg

init : InfoSysId -> Session.Model -> ( Model, Cmd Msg )
init isId session =
  let 
    model = 
      { data = RemoteData.Loading
      , session = session
      }
  in
  ( model , fetchIS isId model)


fetchIS : InfoSysId ->  {a | session : Session.Model} -> Cmd Msg
fetchIS isId {session} =
  let
    baseUrl = Session.getApi session |> Url.toString
    qry = 
      (Q.param "id" <| Q.eq <| Q.int <| InfoSysSummary.idToInt isId)
      :: defaultQry
      |> Q.toQueryString 

    url = baseUrl ++ "info_system" ++ "?" ++ qry

    reqConfig = 
      apiConfig session.session
      |> Api.apiSingleResult 
      |> Api.apiConfigToRequestConfig
  in
    RemoteData.Http.getWithConfig reqConfig url
      ISReceived dtDecoder


defaultQry : Q.Params
defaultQry =
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
    ]
  ]


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ISReceived data ->
            ( { model | data = data }, Cmd.none )


view : Model -> Html Msg
view model =
    div 
      [class "container mb-5 mt-5 pt-5"]
      ( UI.viewRemoteData (List.singleton << (viewIS model)) model.data      
      )

viewIS : {m| session : Session.Model} -> DT ->  Html Msg 
viewIS {session} data =
    let 
        canEdit = 
          case Session.viewer session.session of
            Just _ -> True
            Nothing -> False
        editHeader = 
          if canEdit then
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

        isTitle = (InfoSysSummary.idToString data.id)
                              ++ "  -  " ++ data.name 

        viewPerson : String -> Person -> List (Html Msg)
        viewPerson lbl person = 
          
            [ div [ class "col-sm-6"] 
              [ blockquote [ class "blockquote blockquote-card text-start"]
                [ p [] [ strong [] [ text lbl]]
                , p [ ] 
                  [ text person.fullname 
                  , a [ href <| "mailto:" ++ (Email.toString person.email) ] 
                    [ UI.getIcon "it-email" [] ]
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
      [ div [ class "card-wrapper card-space" ]
        [ div [class "card card-bg card-big"]
          ( editHeader ++ 
            [ div [ class "card-body"]
              [ div [ class "row" ] 
                [ div [class "col-1"] 
                  [ div [ class "top-icon h5 text-start"] [ UI.getIcon "it-card" [] ] ]
                , div [class "col-11"] 
                  [ h3 [ class "card-title h"] [ text isTitle ] 
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