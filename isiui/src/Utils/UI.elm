module Utils.UI exposing 
  ( getIcon, getSprite, viewRemoteData
  )

import Html exposing (Html, a, button, div, li, nav, p, span, text, ul,h3)
import Html.Attributes as HAttr exposing (class,  href, style, attribute)
import Html.Events exposing (onClick)
import Route exposing (Route)
import Session.Viewer exposing (Viewer)
import Svg exposing (svg)
import Svg.Attributes as SvgAttr

import RemoteData exposing (RemoteData)
import Http

getIcon name attr = 
  let
    link = getSprite name
  in
  svg
    ((SvgAttr.class "icon") :: attr)
    [ Svg.use
        [ attribute "href" link
        , attribute "xlink:href" link
        ]
        []
    ]

getSprite name = "/bootstrap-italia_v220/svg/sprites.svg#" ++ name


viewRemoteData : (a -> List (Html msg)) -> RemoteData Http.Error a  -> List (Html msg)
viewRemoteData f data = 
  case data of
    RemoteData.Success value ->
      f value

    RemoteData.Loading ->
        [ h3 [] [text "caricamento in corso" ] ]

    RemoteData.NotAsked ->
        [ h3 [][ text "non avviato" ]]

    RemoteData.Failure error ->
        [ h3 [] [text (buildErrorMessage error)] ]
        


buildErrorMessage : Http.Error -> String
buildErrorMessage httpError =
    case httpError of
        Http.BadUrl message ->
            message

        Http.Timeout ->
            "Server is taking too long to respond. Please try again later."

        Http.NetworkError ->
            "Unable to reach server."

        Http.BadStatus statusCode ->
            "Request failed with status code: " ++ String.fromInt statusCode

        Http.BadBody message ->
            message
