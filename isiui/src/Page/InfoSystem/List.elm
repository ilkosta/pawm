module Page.InfoSystem.List exposing 
  ( Model
  , Msg
  , init, update, view, subscriptions)

import Html.Events exposing (onClick)

import Dict

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
-- import Data.BasePageData as BasePageData
import Url
-- import Utils.Error.LoadingProblem  as Problem
import Postgrest.Queries as Q
import Email
import Svg.Attributes exposing (in_)


type alias DT = List InfoSysSummary.InfoSysSummary

type alias FilterValue = 
  { field : String
  , value : String
  , readable : String
  }

type alias FilterName = String
type alias Filters = Dict.Dict FilterName FilterValue

type alias Model =
  { data : WebData DT
  , session : Session.Model
  -- , problems : List Problem.Problem
  , filters : Filters
  }



type Msg
    = FetchInfosystems
    | InfosysReceived (WebData DT)
    | AddFilter FilterName FilterValue
    | RemoveFilter FilterName
    



init : Session.Model -> ( Model, Cmd Msg )
init session =
  let 
    model = 
      { data = RemoteData.Loading
      , session = session
      , filters = Dict.empty
      }
  in
  ( model , fetchIS model)





fetchIS : {a | session : Session.Model, filters : Filters } -> Cmd Msg
fetchIS {session, filters} =
  let
    baseUrl = Session.getApi session |> Url.toString
    qry = 
      filteredList filters 
      |> Q.toQueryString 
    url = baseUrl ++ "info_system" ++ "?" ++ qry |> Debug.log "qry:"
  in
    RemoteData.Http.getWithConfig (apiConfig session.session)
      url
      InfosysReceived (Data.InfoSysSummary.decoder |> Decode.list)


defaultListQry : Q.Params
defaultListQry =
  [ Q.select 
    [ Q.attribute "id"
    , Q.attribute "name"
    , Q.attribute "description"
    , Q.attribute "finality"
    , Q.resourceWithParams "resp:address_book!resp_email"
      [] (Q.attributes [ "fullname", "email", "legal_structure_name"])
    ]
  ]

filteredList : Filters -> Q.Params
filteredList filters =
  let
    filter2param _ v = Q.param v.field (Q.eq (Q.string v.value))
  in
  Dict.map filter2param filters
  |> Dict.toList
  |> List.map Tuple.second
  |> List.singleton 
  |> List.append [defaultListQry]
  |> Q.concatParams 

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        FetchInfosystems ->
            ( { model | data = RemoteData.Loading }
            , fetchIS model
            )

        InfosysReceived data ->
            ( { model | data = data }, Cmd.none )

        AddFilter name value ->
          let
              nM = { model | filters = Dict.insert name value model.filters }
          in          
          ( nM , fetchIS nM)

        RemoveFilter name -> 
          let
            nM = { model | filters = Dict.remove name model.filters }
          in
          ( nM , fetchIS nM)
        




-- VIEWS


view : Model -> Html Msg
view model =
    div 
      [class "container mb-5 mt-5 pt-5"]
      ( -- List.append (List.map Problem.viewProblems model.problems)
        Utils.UI.viewRemoteData (List.singleton << (viewInfoSystems model.filters)) model.data 
      
      )



viewInfoSystems : Filters -> DT ->  Html Msg 
viewInfoSystems filters data = 
  div [] 
  [ if Dict.isEmpty filters 
    then div[][]
    else 
      div [class "row"]
      [ div [ class "callout note"] 
        [ div [ class "callout-title"]
          [ Utils.UI.getIcon "it-info-circle" []
          , text "Filtri attivi:" 
          ]
        , div [ class "row"] 
          (Dict.map viewFilter filters |> Dict.toList |> List.map Tuple.second)        
        ]
      ]
  , div [ class "row" ] 
    (List.map (viewSingleInfoSys True) data )
  ]

viewFilter : FilterName -> FilterValue -> Html Msg
viewFilter k v =
  let
    lbl = k ++ ": " ++ v.readable
  in
    div [ class "col-12 col-md-8"]
    [ div
      [ class "chip chip-primary chip-lg chip-simple"
      ]
      [ span
          [ class "chip-label"
          ]
          [ text lbl ]
      , button
          [ onClick <| RemoveFilter k
          ]
          [ Utils.UI.getIcon "it-close" [] 
          , span
              [ class "visually-hidden"
              ]
              [ text "Elimina label" ]
          ]
      ]
    ]
    


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
                      [ class "card-signature text-decoration-underline "
                      , onClick <| 
                        AddFilter "responsabile" 
                        { field = "resp_email"
                        , value = Email.toString data.respEmail
                        , readable = data.respName
                        }
                      ]
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