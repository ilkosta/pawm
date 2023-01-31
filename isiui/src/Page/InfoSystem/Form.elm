module Page.InfoSystem.Form exposing
    ( Form
    , Msg(..)
    , emptyForm
    , TrimmedForm 
    , infoSys2Form
    , form2infoSys
    , fetchPeople
    , fetchUO

    , view
    , validate
    , ValidatedField
    )

import Data.InfoSystem exposing (InfoSystem)
import Data.InfoSysSummary as ISS
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Url
import Utils.Email
import Utils.Error.EditProblem as Prob exposing (Problem, viewProblem)
import Email
import Route
import Utils.Url exposing (emptyUrl)
import SingleSelect
import Data.Person exposing (Person)
import Api
import RemoteData exposing (WebData)
import RemoteData.Http
import Json.Decode as Decode
import Session.Session as Session
import Postgrest.Queries as Q
import Utils.UI
import Data.UO exposing (UO)


{-| Recording validation problems on a per-field basis facilitates displaying
them inline next to the field where the error occurred.

This facilitate the applications of owasp reccomandations 
https://cheatsheetseries.owasp.org/cheatsheets/Input_Validation_Cheat_Sheet.html
by isolating in a uniq module the form management

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
    , respSelect : SingleSelect.SmartSelect Msg Person
    , respSelected : Maybe Person
    , people : WebData Data.Person.People
    , respInfSelect : SingleSelect.SmartSelect Msg Person
    , respInfSelected : Maybe Person
    , uoSelected : Maybe UO
    , uoSelect : SingleSelect.SmartSelect Msg UO
    , uoList : WebData (List UO)
    }

initPersonSelect : 
  (( Person, SingleSelect.Msg Person ) -> Msg) 
  -> (SingleSelect.Msg Person -> Msg)
  -> SingleSelect.SmartSelect Msg Person
initPersonSelect hSelection hSelectUpdate =
  SingleSelect.init 
    { selectionMsg = hSelection 
    , internalMsg = hSelectUpdate
    -- , characterSearchThreshold = 3
    -- , debounceDuration = 500.0 -- milliseconds
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
    ---
    , respSelect = 
        initPersonSelect 
          HandleRespSelection
          HandleRespSelectUpdate        
    , respSelected = Nothing
    , people = RemoteData.NotAsked

    , respInfSelect = 
        initPersonSelect 
          HandleRespInfSelection
          HandleRespInfSelectUpdate        
    , respInfSelected = Nothing

    , uoSelect = 
        SingleSelect.init 
        { selectionMsg = HandleUOSelection 
        , internalMsg = HandleUOSelectUpdate
        }   
    , uoSelected = Nothing
    , uoList = RemoteData.NotAsked
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
    , respSelected = Nothing
    , respSelect = 
        initPersonSelect 
          HandleRespSelection
          HandleRespSelectUpdate
    , respInfSelected = Nothing
    , respInfSelect = 
        initPersonSelect 
          HandleRespInfSelection
          HandleRespInfSelectUpdate
    , people = RemoteData.NotAsked

    , uoSelect = 
        SingleSelect.init 
        { selectionMsg = HandleUOSelection 
        , internalMsg = HandleUOSelectUpdate
        }   
    , uoSelected = Nothing
    , uoList = RemoteData.NotAsked
    }


------

fetchPeople : {a | session : Session.Model} -> Cmd Msg
fetchPeople {session} = 
  let
    reqConfig = 
      Api.apiConfig session.session
      |> Api.apiConfigToRequestConfig
    
    baseUrl = Session.getApi session |> Url.toString
    url = 
      baseUrl ++ "address_book?" ++
      ( [ Q.select <| Q.attributes ["fullname","pa_role","legal_structure_name","email"]
        , Q.order [Q.asc "fullname" ]
        ] |> Q.toQueryString
      )
  in
    RemoteData.Http.getWithConfig reqConfig url
      HandlePeopleResponse (Decode.list Data.Person.decoder)


fetchUO: {a | session : Session.Model} -> Cmd Msg
fetchUO {session} = 
  let
    reqConfig = 
      Api.apiConfig session.session
      |> Api.apiConfigToRequestConfig
    
    baseUrl = Session.getApi session |> Url.toString
    url = 
      baseUrl ++ "uo?" ++
      ( [ Q.select <| Q.attributes ["id","coddesc","description"]
        , Q.order [Q.asc "description" ]
        ] |> Q.toQueryString
      )
  in
    RemoteData.Http.getWithConfig reqConfig url
      HandleUOResponse (Decode.list Data.UO.decoder)      
------

form2infoSys : TrimmedForm -> InfoSystem
form2infoSys (Trimmed f)  =
  let
    email maybePerson = 
      Maybe.map (\p -> p.email) maybePerson
  in
  { id = Maybe.map ISS.idFromInt f.id
  , name = f.name
  , description = f.description
  , finality = f.finality
  , uo = Maybe.map (.id) f.uoSelected
          |> Maybe.withDefault 0 
  , passPrj = 
      Url.fromString f.passUrl
      |> Maybe.withDefault emptyUrl
  , resp = email f.respSelected |> Maybe.withDefault Utils.Email.emptyEmail  
  , respInf = email f.respInfSelected
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
    | Resp
    | RespInf


fieldsToValidate : List ValidatedField
fieldsToValidate =
    [ Name
    , Description
    -- , Finality
    , PassUrl
    , Resp
    , RespInf
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
        , respSelect = form.respSelect
        , respSelected = form.respSelected
        , people = form.people
        , respInfSelect = form.respInfSelect
        , respInfSelected = form.respInfSelected
        , uoList = form.uoList
        , uoSelect = form.uoSelect
        , uoSelected = form.uoSelected
        }

-- https://web.archive.org/web/20170717174432/https://ipsec.pl/python/2017/input-validation-free-form-unicode-text-python.html/
unicodeNormalize : Form -> Form
unicodeNormalize form = 
  -- TODO: da implementare
  form

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
            
            Resp ->
              let errmsg = ["occorre selezionare almeno un responsabile per il sistema"] in
              case form.respSelected of
                Nothing -> errmsg
                Just r ->
                  if r.email == Utils.Email.emptyEmail 
                  then errmsg
                  else []

            RespInf ->
              let errmsg = ["occorre indicare almeno un responsabile informatico per il sistema"] in
              case form.respSelected of
                Nothing -> errmsg
                Just r -> 
                  if String.contains "infor" r.uo 
                  then []
                  else 
                    case form.respInfSelected of
                      Nothing -> errmsg
                      Just ri -> 
                        if ri.email == Utils.Email.emptyEmail
                        then errmsg
                        else []

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
    ---
    | HandlePeopleResponse  (WebData Data.Person.People)
    | HandleUOResponse      (WebData (List UO))
    ---
    | HandleRespSelectUpdate (SingleSelect.Msg Person)
    | HandleRespSelection (Person, SingleSelect.Msg Person)
    | HandleRespInfSelectUpdate (SingleSelect.Msg Person)
    | HandleRespInfSelection (Person, SingleSelect.Msg Person)
    | HandleUOSelectUpdate (SingleSelect.Msg UO)
    | HandleUOSelection (UO, SingleSelect.Msg UO)

view : (Msg -> msg) -> {m | form : Form, problems : List (Problem ValidatedField)} -> Html.Html msg
view toMsg {form, problems} =
  div 
  [ class "container mb-8 mt-8 pt-8"
  ]            
  [ div [class "row"]
      [ div [ class "col-md-8 offset-md-3 col-xs-12" ]
          [ ul [ class "error-messages" ]
              (List.map viewProblem problems)
          
          ]
      ]

  , viewForm toMsg form
  ]


viewForm : (Msg -> msg) -> Form -> Html.Html msg
viewForm toMsg form =
    let
        inputClasses =
            class "form-control"

        fieldGroup : Int -> List (Html msg) -> Html msg
        fieldGroup size =
            Html.fieldset [ class ("form-group col-md-" ++ (String.fromInt size)) ]

        lbl_ dest val customClass = 
          Html.label 
            [ for dest, class ("form-label" ++ " " ++ customClass) ] 
            [ Html.text val ]

        lblForStr dest val data =
          let
            classes = 
              if String.isEmpty data
              then ""
              else "active"
          in
            lbl_ dest val classes

        lbl dest val = lbl_ dest val ""
        onin message = Html.Events.onInput (toMsg << message) 

        defSize = 12
    in    
    Html.form [ onSubmit (toMsg SubmittedForm), class "form-floating" ]
      [ fieldGroup defSize
          [ lblForStr "name" "Nome sistema" form.name
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
      
      
      
      , fieldGroup defSize
          [ lblForStr "description" "Descrizione breve" form.description
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
      , fieldGroup defSize
          [ lblForStr "finality" "Descrizione estesa" form.finality
          , textarea
              [ inputClasses
              , placeholder "indicare scopo, finalita', scenari utili"
              , onin EnteredFinality
              , value form.finality
              , id "finality"

              -- , type_ "text"
              , rows 5
              , height 10
              ]
              []
          ]
      , fieldGroup defSize
          [ lbl_ "uo" "Unita' Organizzativa di competenza" "active"
          , div [ style "text-align" "left" ]
            ( Utils.UI.viewRemoteData 
                ( \uo ->
                    ( SingleSelect.view 
                        { selected = form.uoSelected
                        , optionLabelFn = \p -> p.description
                        , options = uo
                        }
                        form.uoSelect
                    ) |> Html.map toMsg |> List.singleton                                       
                )
                form.uoList
            )            
          ]
      , fieldGroup defSize
          [ lblForStr "pass_url" "Url del progetto su Pass" form.passUrl
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
      , div [ class "row" ]
        [ fieldGroup 4
          [ lbl_ "resp" "Responsabile del sistema" "active"
          , div [ style "text-align" "left" ]
            ( Utils.UI.viewRemoteData 
                ( \people ->
                    ( SingleSelect.view 
                        { selected = form.respSelected
                        , optionLabelFn = \p -> p.fullname
                        , options = people
                        }
                        form.respSelect
                    ) |> Html.map toMsg |> List.singleton                                       
                )
                form.people
            )            
          ]  
        , fieldGroup 4
          [ lbl_ "resp" "Responsabile informatico del sistema" "active"
          , div [ style "text-align" "left" ]
            ( Utils.UI.viewRemoteData 
                ( \people ->
                    ( SingleSelect.view 
                        { selected = form.respInfSelected
                        , optionLabelFn = \p -> p.fullname
                        , options = people
                        }
                        form.respInfSelect
                    ) |> Html.map toMsg |> List.singleton                                       
                )
                form.people
            )            
          ]
        ]  

      , div
          [ class "d-grid gap-2 d-md-flex justify-content-md-end" ]
          [ a
              [ class "btn btn-lg btn-outline-primary pull-xs-left"
              , Route.href Route.Home
              ]
              [ text "Annulla" ]
          , button
              [ class "btn btn-lg btn-primary pull-xs-right"]
              [ text "Salva" ]
          ]
      ]
      
