module Utils.Error.EditProblem exposing (Problem(..), viewProblem)
import Html exposing (..)
import Html.Attributes exposing (..)
import Svg exposing (svg)
-- import Svg.Attributes as SvgAttr

type Problem f
    = InvalidEntry f String
    | ServerError String

viewProblem : Problem f -> Html msg
viewProblem problem =
    let
        source = 
          case problem of
              InvalidEntry _ _ ->
                  "Errore nella validazione dei dati"

              ServerError _ ->
                  "Errore di comunicazione con il server"

        errorMessage =
            case problem of
                InvalidEntry _ str ->
                    str

                ServerError str ->
                    str
    in
    div
        [ class "row"
        ]
        [ div
            [ class "col-12 col-lg-6"
            ]
            [             {-start card-}
              div
                [ class "card-wrapper card-space"
                ]
                [ div
                    [ class "card card-bg"
                    ]
                    [ div
                        [ class "card-body"
                        ]
                        [ h3
                            [ class "card-title h5 text-danger"
                            ]
                            [ text source ]
                        , p
                            [ class "card-text text-danger"
                            ]
                            [ text errorMessage ]                        
                        ]
                    ]
                ]
              {-end card-}
            ]
        ]
    
