module Page.Home exposing (view)

{-| The homepage. You can get here via either the / or /#/ routes.
-}

import Html exposing (Html,h1,text)


-- VIEW


view : Html msg
view =
    h1 [] [ text "Benvenuto" ]
