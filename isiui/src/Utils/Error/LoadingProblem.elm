module Utils.Error.LoadingProblem exposing (viewProblems,Problem(..))

import Html exposing (..)
import Html.Attributes exposing (..)
import Svg exposing (svg)
import UI 

type Problem
    = ServerError String


viewProblems : Problem -> Html msg
viewProblems problem =
    let
        errorMessage =
            case problem of
                ServerError str ->
                    str
    in
        div
        [ class "notification with-icon error"
        , attribute "role" "alert"
        , attribute "aria-labelledby" "not2b-title"
        , id "not2b"
        ]
        [ h2
            [ id "not2b-title"
            , class "h5 "
            ]
            [ UI.getIcon "it-close-circle" []
            , text "Errore nella comunicazione con il server" 
            ]
        , span[][ text errorMessage ]
        ]
    
    
