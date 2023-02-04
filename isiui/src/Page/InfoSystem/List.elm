module Page.InfoSystem.List exposing 
  ( Model
  , Msg
  , init, update, view, subscriptions)

import Html.Events exposing (onClick)

import Dict

import Html exposing (Html, a, button, div, p, span, text,h3,label,input)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Utils.UI as UI


import Json.Decode as Decode
import Data.InfoSysSummary
import RemoteData exposing (WebData)
import RemoteData.Http
import Route 
import Data.InfoSysSummary as InfoSysSummary
import Api exposing (apiConfig)
import Session.Session as Session
-- import Data.BasePageData as BasePageData
import Url
-- import Utils.Error.LoadingProblem  as Problem
import Postgrest.Queries as Q
import Email
import Html.Attributes exposing (placeholder)
import Html.Events exposing (onInput)
import Session.Viewer as Viewer
import Http
import Data.InfoSysSummary as InfoSysSummary exposing (InfoSysId)
import Svg.Attributes as SvgAttr
import Data.Bookmark as Bookmark
import RemoteData exposing (RemoteData(..))


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
  , error : Maybe String
  }



type Msg
  = FetchInfosystems
  | InfosysReceived (WebData DT)
  | AddFilter FilterName FilterValue
  | RemoveFilter FilterName
  | SearchMsg String
  | BookmarkMsg InfoSysSummary.InfoSysId
  | BookmarkedMsg (Result Http.Error Bookmark.Bookmark)
    



init : Session.Model -> ( Model, Cmd Msg )
init session =
  let 
    model = 
      { data = RemoteData.Loading
      , session = session
      , filters = Dict.empty
      , error = Nothing
      }
  in
  ( model , fetchIS model)





fetchIS : {a | session : Session.Model, filters : Filters } -> Cmd Msg
fetchIS {session, filters} =
  let
    baseUrl = Session.getApi session |> Url.toString
    qry = 
      filteredList session.session filters 
      |> Q.toQueryString 
    url = baseUrl ++ "info_system" ++ "?" ++ qry |> Debug.log "qry:"

    reqConfig = 
      apiConfig session.session
      |> Api.apiConfigToRequestConfig
  in
    RemoteData.Http.getWithConfig reqConfig
      url
      InfosysReceived (Decode.list Data.InfoSysSummary.decoder)


defaultListQry : Session.Session -> Q.Params
defaultListQry session =
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
    , Q.resourceWithParams "resp:address_book!resp_email"
      [] (Q.attributes [ "fullname", "email"])
    , Q.resourceWithParams "uo"
      [] (Q.attributes [ "description"])
    , Q.resourceWithParams "authorizations"
      meParams
      (Q.attributes [ "email"])
    , Q.resourceWithParams "observers"
      meParams
      (Q.attributes [ "email"])
    ]
  , Q.order [ Q.asc "id" ]  
  ]

filteredList : Session.Session -> Filters -> Q.Params
filteredList session filters =
  let
    filter2param _ v = Q.param v.field (Q.eq (Q.string v.value))
  in
  Dict.map filter2param filters
  |> Dict.toList
  |> List.map Tuple.second
  |> List.singleton 
  |> List.append [defaultListQry session]
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

        SearchMsg txt ->
          ( model
          , search model.session txt
          )

        BookmarkMsg id ->
          ( model, sendBookmark model id )

        BookmarkedMsg (Result.Ok bmk) -> 
          case model.data of
            Success d_ ->
              let
                d = 
                  List.map 
                    (\is -> 
                      if (InfoSysSummary.idToInt is.id) == (InfoSysSummary.idToInt bmk.id) 
                      then { is | observed = not is.observed}
                      else is
                    )
                  d_
              in
              ( {model | data = Success d}, Cmd.none)
            _ -> ( model, Cmd.none)
          

        BookmarkedMsg (Result.Err err) -> 
          ( { model | error = Just <| UI.buildErrorMessage err }
          , Cmd.none
          )


search : Session.Model -> String -> Cmd Msg
search session q =
  let
    baseUrl = Session.getApi session |> Url.toString
    txt = "*" ++ q ++ "*"
    qry = 
      ( if String.isEmpty q && String.length q > 3
        then []
        else
          List.map  
            (\f -> Q.param f (Q.ilike txt) )
            ["name","description","finality","resp_email","resp_inf_email"]
          |> Q.or 
          |> List.singleton 
      )
      |> List.append (defaultListQry session.session)
      |> Q.toQueryString 
    url = baseUrl ++ "info_system" ++ "?" ++ qry

    reqConfig = 
      apiConfig session.session
      |> Api.apiConfigToRequestConfig
  in
    if String.length q > 3
    then
      RemoteData.Http.getWithConfig reqConfig url
        InfosysReceived (Decode.list Data.InfoSysSummary.decoder)
    else 
      Cmd.none


sendBookmark : Model -> InfoSysSummary.InfoSysId -> Cmd Msg
sendBookmark model id = 
  case model.data of
    Success d_ ->
      let
        bookmarked = 
          List.filter 
            (\is -> InfoSysSummary.idToInt is.id == InfoSysSummary.idToInt id) 
            d_
          |> List.head
          |> Maybe.map .observed
          |> Maybe.withDefault False
      in
        Api.sendBookmark BookmarkedMsg 
          model.session bookmarked id

    _ -> Cmd.none

-- VIEWS


view : Model -> Html Msg
view model =
    div 
      [class "container mb-5 mt-5 pt-5"]
      ( List.append [viewSearchBar] <|
        UI.viewRemoteData (List.singleton << (viewInfoSystems model)) model.data      
      )
      

viewSearchBar : Html Msg
viewSearchBar =
  div [ class "form-group autocomplete-wrapper-big"]
  [ label [ for "searchbar", class "visually-hidden"] [text "Cerca tra i sistemi censiti"]
  , input 
    [ type_ "search"
    , class "autocomplete"
    , placeholder "Testo da cercare nei sistemi"
    , id "searchbar"
    , onInput SearchMsg
    ][]
  , span [ class "autocomplete-icon", attribute "aria-hidden" "true"] 
    [ UI.getIcon "it-search" [] ]
  ]



viewInfoSystems : {a| filters: Filters, session: Session.Model} -> DT ->  Html Msg 
viewInfoSystems {filters,session} data = 
  div [] 
  [ if Dict.isEmpty filters 
    then div[][]
    else 
      div [class "row"]
      [ div [ class "callout note"] 
        [ div [ class "callout-title"]
          [ UI.getIcon "it-info-circle" []
          , text "Filtri attivi:" 
          ]
        , div [ class "row"] 
          (Dict.map viewFilter filters |> Dict.toList |> List.map Tuple.second)        
        ]
      ]
  , div [ class "row" ] 
    (List.map (viewSingleInfoSys session.session) data )
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
          [ UI.getIcon "it-close" [] 
          , span
              [ class "visually-hidden"
              ]
              [ text "Elimina label" ]
          ]
      ]
    ]
    


viewSingleInfoSys : Session.Session -> InfoSysSummary.InfoSysSummary ->  Html Msg 
viewSingleInfoSys session data  =
  let

    editHeader = 
      if Api.canEdit session data 
      then
          [ div
            [ class "etichetta"
            ]
            [ UI.getIcon "it-pencil" []                    
            , a [ Route.href (Route.ISEdit data.id)]
                [ text "Modifica" ]
            , span -- per l'accessibilita' tramite screen reader
              [ class "visually-hidden" ]
              [ text ("modifica il sistema informativo " ++ data.name) ]
            ]
          ]
      else []


    isTitle = (InfoSysSummary.idToString data.id)
              ++ "  -  " ++ data.name 

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
        (Session.viewer session)  
      |> Maybe.withDefault (span [] [])
  in

    div
        [ class "col-12 col-lg-6"
        ]
        [             {-start card-}
        div
            [ class "card-wrapper card-space"
            ]
            [ div
                [ class "card card-bg card-big border-bottom-card"
                , style "padding" "10px"
                ]
                (editHeader ++ 
                [ bookmark
                , div
                    [ class "card-body"
                    ]
                    [ h3
                          [ class "card-title h5 no_toc" ]
                          [ text isTitle ]
                      , p
                          [ class "card-text" ]
                          [ text data.description ]
                    ]
                ------
                , div [ class "id-card-footer"]
                  [ span
                      [ class "card-signature text-decoration-underline"
                      , onClick <| 
                        AddFilter "responsabile" 
                        { field = "resp_email"
                        , value = Email.toString data.respEmail
                        , readable = data.respName
                        }
                      ]
                      [ text  data.respName ]
                  , p [ class "card-signature"]
                      [ text data.uo]
                    
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
                      , UI.getIcon "it-arrow-right" []                            
                      ]
                  ]
                ])
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