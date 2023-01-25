module Page.NotFound exposing (view)

import Html exposing (Html,h1,text)


-- VIEW


view : Html msg
view =
    h1 [] [ text "OPS! non sono riuscito a trovare la pagina :(" ]
