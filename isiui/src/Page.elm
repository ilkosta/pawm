module Page exposing (Page(..), needAuth, viewPage)

import Html exposing (Html, a, button, div, li, nav, p, span, text, ul)
import Html.Attributes as HAttr exposing (class,  href, style, attribute)
import Html.Events exposing (onClick)
import Route exposing (Route)
import Session.Viewer exposing (Viewer)
import Svg exposing (svg)
import Svg.Attributes as SvgAttr

import Utils.UI exposing (..)

import Browser exposing (Document)

import Page.InfoSystem.List as ListInfoSys
import Page.InfoSystem.Edit as ISEdit


import Session.Viewer exposing (Viewer)

type Page
    = NotFoundPage
    | HomePage
    | ListPage ListInfoSys.Model  
    | ISEditPage ISEdit.Model


needAuth : Route -> Bool
needAuth route =
  case route of
      Route.Home -> False
      Route.NotFound -> False
      Route.ISList -> False
      Route.ISEdit _ -> True
      Route.ISDetails _ -> False



{-| Take a page's Html and frames it with a header and footer.

The caller provides the current user, so we can display in either
"signed in" (rendering username) or "signed out" mode.

isLoading is for determining whether we should show a loading spinner
in the header. (This comes up during slow page transitions.)

-}
viewPage : Maybe Viewer 
            -> Page 
            -> { title : String, content : List (Html msg) } 
            -> Document msg
viewPage maybeViewer page { title, content } =
    { title = "ISI - " ++ title
    , body = 
        List.append 
          (viewHeader page maybeViewer)
          content
    }

viewHeader : Page -> Maybe Viewer -> List (Html msg)
viewHeader page maybeViewer =
    [ slimHeader    page maybeViewer
    , centralHeader page maybeViewer
    ]    


slimHeader : Page -> Maybe Viewer ->  Html msg
slimHeader page maybeViewer =
    div
        [ class "it-header-slim-wrapper"
        , class "it-header-sticky"      -- visibile in formato ridotto anche allo scorrere della pagina
        ]
        [ div
            [ class "container"
            ]
            [ div
                [ class "row" ]
                [ div
                    [ class "col-12" ]
                    [ div
                        [ class "it-header-slim-wrapper-content" ]
                        [ a [ class "d-none d-lg-block navbar-brand"
                            , href "#"
                            ]
                            [ text "Regione Marche" ]
                        , div
                            [ class "nav-mobile" ]
                            [ nav
                                [ attribute "aria-label" "Navigazione accessoria" ]
                                [ a
                                    [ class "it-opener d-lg-none"
                                    , attribute "data-bs-toggle" "collapse"
                                    , href "#menu1a"
                                    , attribute "role" "button"
                                    , attribute "aria-expanded" "false"
                                    , attribute "aria-controls" "menu4"
                                    ]
                                    [ span []
                                        [ text "Regione Marche" ]
                                    , svg
                                        [ SvgAttr.class "icon"
                                        , attribute "aria-hidden" "true"
                                        ]
                                        [ Svg.use
                                            [ attribute "href" <| getSprite "it-expand" ]
                                            []
                                        ]
                                    ]
                                , div
                                    [ class "link-list-wrapper collapse"
                                    , HAttr.id "menu1a"
                                    ]
                                    (navPages page maybeViewer)
                                ]
                            ]
                        , loginBtn maybeViewer
                        ] 
                    ]
                ]
            ]
        ]


loginBtn : Maybe Viewer -> Html msg
loginBtn maybeViewer =
  -- let
  --     _ = Debug.log "userid" <| Maybe.map Viewer.userId maybeViewer
  --     _ = Debug.log "email" <| Maybe.map Viewer.email maybeViewer
  --     _ = Debug.log "name" <| Maybe.map Viewer.fullName maybeViewer
  -- in
  div
    [ class "it-header-slim-right-zone" ]
    [ 
    --   a [class "nav-item",href "#/"] [text <|Maybe.withDefault "" <| Maybe.map Viewer.fullName maybeViewer]
    -- , 
      div
        [ class "it-access-top-wrapper" ]
        [ a
            [ class "btn btn-primary btn-sm"
            -- TODO: , Route.href <| if maybeViewer == Nothing then Route.Login  else Route.Logout               
            ]
            [ text <| if maybeViewer == Nothing then "Accedi" else "Esci" ]
        ]
    ]
  

navPages : Page -> Maybe Viewer -> List (Html msg)
navPages currPage maybeViewer =
  let
    linkTo = navbarLink currPage
    pubLinks = 
      [ linkTo Route.Home "Home"
      , linkTo Route.ISList "Elenco"
      ]
    privateLinks = 
      [ 
      ]
    links = 
      if maybeViewer == Nothing 
      then pubLinks
      else (pubLinks ++ privateLinks)

  in
    [ ul
        [ class "link-list" ] 
        links
    ]


isActivePage : Page -> Route -> Bool
isActivePage page route = 
  case ( page, route ) of
    ( HomePage, Route.Home ) ->
        True

    ( ListPage _, Route.ISList ) -> True

    _ -> 
        False 


navbarLink : Page -> Route -> String -> Html msg
navbarLink page route lnkText =
  let
    attributes =
            [ class "list-item"
            , Route.href route
            ]

          
  in
    if isActivePage page route then
      li  []
          [ a
              (
                List.append attributes 
                [ attribute "aria-current" "page"
                , class "active"
                ]
              )
              [text (lnkText ++ " (Attivo)")]
          ]
    else
      li  []
          [ a (List.append [class "dropdown-item"] attributes )
              [text lnkText] 
          ]

-- CENTRAL HEADER
centralHeader : Page -> Maybe Viewer ->  Html msg
centralHeader page maybeViewer = 
    div
        [ class "it-header-center-wrapper it-small-header"
        ]
        [ div
            [ class "container"
            ]
            [ div
                [ class "row"
                ]
                [ div
                    [ class "col-12"
                    ]
                    [ div
                        [ class "it-header-center-content-wrapper"
                        ]
                        [ div
                            [ class "it-brand-wrapper"
                            ]
                            [ a
                                [ href "#"
                                ]
                                [ svg
                                    [ SvgAttr.class "icon"
                                    , attribute "aria-hidden" "true"
                                    ]
                                    [ Svg.use
                                        [ attribute "href" <| getSprite "it-pa"
                                        ]
                                        []
                                    ]
                                , div
                                    [ class "it-brand-text"
                                    ]
                                    [ div
                                        [ class "it-brand-title"
                                        ]
                                        [ text "ISI" ]
                                    , div
                                        [ class "it-brand-tagline d-none d-md-block"
                                        ]
                                        [ text "Inventario Sistemi Informatici" ]
                                    ]
                                ]
                            ]
                        , div
                            [ class "it-right-zone"
                            ]
                            [ 
                              div
                                [ class "it-socials d-none d-md-flex"
                                ]
                                [ span []
                                    [ text "Seguici su" ]
                                , ul []
                                    [ li []
                                        [ a
                                            [ href "https://github.com/ilkosta/pwam"
                                            , attribute "aria-label" "Github"
                                            , HAttr.target "_blank"
                                            ]
                                            [ svg
                                                [ SvgAttr.class "icon"
                                                ]
                                                [ Svg.use
                                                    [ attribute "href" <| getSprite "it-github"
                                                    ]
                                                    []
                                                ]
                                            ]
                                        ]
                                    ]
                                ]
                            , div
                                [ class "it-search-wrapper"
                                ]
                                [ span
                                    [ class "d-none d-md-block"
                                    ]
                                    [ text "Cerca" ]
                                , a
                                    [ class "search-link rounded-icon"
                                    , attribute "aria-label" "Cerca nel sito"
                                    , href "#"
                                    ]
                                    [ svg
                                        [ SvgAttr.class "icon"
                                        ]
                                        [ Svg.use
                                            [ attribute "href" <| getSprite "it-search"
                                            ]
                                            []
                                        ]
                                    ]
                                ]
                            ]
                        ]
                    ]
                ]
            ]
        ]
    

{-| Render dismissable errors. We use this all over the place!
-}
viewErrors : msg -> List String -> Html msg
viewErrors dismissErrors errors =
    if List.isEmpty errors then
        Html.text ""

    else
        div
            [ class "error-messages"
            , style "position" "fixed"
            , style "top" "0"
            , style "background" "rgb(250, 250, 250)"
            , style "padding" "20px"
            , style "border" "1px solid"
            ]
        <|
            List.map (\error -> p [] [ text error ]) errors
                ++ [ button [ onClick dismissErrors ] [ text "Ok" ] ]    