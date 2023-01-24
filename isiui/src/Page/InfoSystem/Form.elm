module Page.InfoSystem.Form exposing
    ( Form
    , Msg(..)
    , emptyForm
    , TrimmedForm 
    , infoSys2Form
    , form2infoSys

    , viewForm
    , validate
    , ValidatedField
    )

import Data.InfoSystem exposing (InfoSystem)
import Data.InfoSysSummary as ISS
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Url
import Utils.Email as EmailUtils
import Utils.Error.EditProblem as Prob exposing (Problem, viewProblem)
import Email
import Route
import Utils.Url exposing (emptyUrl)


{-| Recording validation problems on a per-field basis facilitates displaying
them inline next to the field where the error occurred.

(The other part of this is having a view function like this:

viewFieldErrors : ValidatedField -> List Problem -> Html msg

...and it filters the list of problems to render only InvalidEntry ones for the
given ValidatedField. That way you can call this:

viewFieldErrors Email problems

...next to the `email` field, and call `viewFieldErrors Password problems`
next to the `password` field, and so on.

The `SubmitError` should be displayed elsewhere, since it doesn't correspond to
a particular field.

-}



-- FORM


type alias Form =
    { id : Maybe Int
    , name : String
    , description : String
    , finality : String
    , uo : Int
    , passUrl : String
    , respEmail : String
    , respInfEmail : String
    }


emptyForm : Form
emptyForm =
    { id = Nothing
    , name = ""
    , description = ""
    , finality = ""
    , uo = 0
    , passUrl = ""
    , respEmail = ""
    , respInfEmail = ""
    }


{-| mapping from main data type and simple form rappresentation
-}
infoSys2Form : InfoSystem -> Form
infoSys2Form is =
    { id = Maybe.map ISS.idToInt is.id
    , name = is.name
    , description = is.description
    , finality = is.finality
    , uo = 0
    , passUrl = Url.toString is.passPrj
    , respEmail = Email.toString is.resp
    , respInfEmail = 
        Maybe.map Email.toString is.respInf
        |> Maybe.withDefault ""
    }

form2infoSys : TrimmedForm -> InfoSystem
form2infoSys (Trimmed f)  =
  { id = Maybe.map ISS.idFromInt f.id
  , name = f.name
  , description = f.description
  , finality = f.finality
  , uo = 0
  , passPrj = 
      Url.fromString f.passUrl
      |> Maybe.withDefault emptyUrl
  , resp = 
      Email.fromString f.respEmail
      |> Maybe.withDefault EmailUtils.emptyEmail
  , respInf = Email.fromString f.respInfEmail
  }

{-| Marks that we've trimmed the form's fields, so we don't accidentally send
it to the server without having trimmed it!
-}
type TrimmedForm
    = Trimmed Form


{-| When adding a variant here, add it to `fieldsToValidate` too!
-}
type ValidatedField
    = Name
    | Description
    -- | Finality
    | PassUrl
    | RespEmail
    | RespInfEmail


fieldsToValidate : List ValidatedField
fieldsToValidate =
    [ Name
    , Description
    -- , Finality
    , PassUrl
    , RespEmail
    , RespInfEmail
    ]


{-| Trim the form and validate its fields. If there are problems, report them!
-}
validate : Form -> Result (List (Problem ValidatedField)) TrimmedForm
validate form =
    let
        trimmedForm =
            trimFields form
    in
    case List.concatMap (validateField trimmedForm) fieldsToValidate of
        [] ->
            Ok trimmedForm

        problems ->
            Err problems


{-| Don't trim while the user is typing! That would be super annoying.
Instead, trim only on submit.
-}
trimFields : Form -> TrimmedForm
trimFields form =
    Trimmed
        { id = form.id
        , name = String.trim form.name
        , description = String.trim form.description
        , finality = String.trim form.finality
        , uo = form.uo
        , passUrl = String.trim form.passUrl
        , respEmail = String.trim form.respEmail
        , respInfEmail = String.trim form.respInfEmail
        }


validateField : TrimmedForm -> ValidatedField -> List (Problem ValidatedField)
validateField (Trimmed form) field =
    List.map (Prob.InvalidEntry field) <|
        case field of
            Name ->
                if String.isEmpty form.name then
                    [ "Il nome del sistema informativo non puo' essere vuoto" ]

                else
                    []

            Description ->
                if String.isEmpty form.description then
                    [ "Occorre fornire una descrizione breve del sistema, non puo' essere vuota" ]

                else
                    []

            PassUrl ->
                if String.isEmpty form.passUrl then
                    [ "Occorre gia' essere in possesso dell'url del progetto Pass principale associato al sistema informativo." ]

                else 
                  case Url.fromString form.passUrl of

                      Just passUrl -> 
                        if passUrl.protocol /= Url.Https
                        || passUrl.host /= "pass.regione.marche.it"
                        || String.left 9 passUrl.path /= "/projects"
                        then [ "l'url inserito non sembra puntare a Pass"]
                        else []

                      Nothing -> [ "l'url del progetto su Pass non e' valido"]

            RespEmail ->
                if String.isEmpty form.respEmail then
                    [ "Il nome del responsabile del sistema informativo non puo' essere lasciato in bianco" ]

                else 
                  case Email.fromString form.respEmail of
                    Just _  -> []
                    Nothing -> ["Il formato dell'email non e' corretto"]

            RespInfEmail ->
                case Email.fromString form.respInfEmail of
                    Just _  -> []
                    Nothing -> ["Il formato dell'email non e' corretto"]



--- VIEW


{-| NO-ENCAPSULATION WARNING:
the messages are exported,
so the management responsability is to the importer module
-}
type Msg
    = EnteredName String
    | EnteredDescription String
    | EnteredFinality String
    | EnteredPassUrl String
    | EnteredRespEmail String
    | EnteredRespInfEmail String
    | SubmittedForm


viewForm : (Msg -> msg) -> Form -> Html.Html msg
viewForm toMsg form =
    let
        inputClasses =
            class "form-control form-control-lg"

        fieldGroup =
            Html.fieldset [ class "form-group form-floating" ]

        lbl dest val =
            Html.label [ for dest, class "form-label" ] [ Html.text val ]

        onin message = Html.Events.onInput (toMsg << message) 
    in
    Html.form [ onSubmit (toMsg SubmittedForm), class "form-floating" ]
      [ fieldGroup
          [ lbl "name" "Nome sistema"
          , Html.input
              [ inputClasses
              , placeholder "Nome del sistema informativo"
              , onin EnteredName
              , value form.name
              , id "name"
              , type_ "text"
              ]
              []
          ]
      
      
      , fieldGroup
          [ lbl "description" "Descrizione breve"
          , textarea
              [ inputClasses
              , placeholder "Descrizione breve del sistema informativo"
              , onin EnteredDescription
              , value form.description
              , id "description"

              -- , type_ "text"
              , rows 3
              , height 3
              ]
              []
          ]
      , fieldGroup
          [ lbl "finality" "Descrizione estesa"
          , textarea
              [ inputClasses
              , placeholder "indicare scopo, finalita', scenari utili"
              , onin EnteredFinality
              , value form.finality
              , id "finality"

              -- , type_ "text"
              , rows 10
              , height 10
              ]
              []
          ]
      , fieldGroup
          [ lbl "pass_url" "Url del progetto su Pass"
          , input
              [ inputClasses
              , placeholder "indirizzo del progetot su Pass"
              , onin EnteredPassUrl
              , value form.passUrl
              , id "pass_url"
              , type_ "text"
              ]
              []
          ]
      , fieldGroup
          [ lbl "resp_email" "Email Responsabile del sistema"
          , input
              [ inputClasses
              , placeholder "email del resonsabile del sistema informativo"
              , onin EnteredRespEmail
              , value form.respEmail
              , id "resp_email"
              , type_ "email"
              ]
              []
          ]
      , fieldGroup
          [ lbl "resp_inf_email" "Email Responsabile del sistema"
          , input
              [ inputClasses
              , placeholder "email del resonsabile del sistema informativo"
              , onin EnteredRespInfEmail
              , value form.respInfEmail
              , id "resp_inf_email"
              , type_ "email"
              ]
              []
          ]
      , div
          [ class "d-grid gap-2 d-md-flex justify-content-md-end" ]
          [ a
              [ class "btn btn-lg btn-outline-primary pull-xs-left"
              , Route.href Route.Home
              ]
              [ text "Annulla" ]
          , button
              [ class "btn btn-lg btn-primary pull-xs-right" ]
              [ text "Conferma" ]
          ]
      ]
      
