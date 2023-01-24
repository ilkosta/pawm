module UI exposing 
  ( getIcon
  )

import Html exposing (Html, a, button, div, li, nav, p, span, text, ul)
import Html.Attributes as HAttr exposing (class,  href, style, attribute)
import Html.Events exposing (onClick)
import Route exposing (Route)
import Session.Viewer exposing (Viewer)
-- import Session exposing (Session)
-- import Username exposing (Username)
import Svg exposing (svg)
import Svg.Attributes as SvgAttr

getIcon name attr = 
  svg
    ((SvgAttr.class "icon") :: attr)
    [ Svg.use
        [ attribute "href" <| getSprite name
        ]
        []
    ]

getSprite name = "/bootstrap-italia_v203/svg/sprites.svg#" ++ name