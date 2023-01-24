module Page.InfoSystem.Edit exposing (..)

import RemoteData.Http
import RemoteData exposing (WebData)

import Html exposing (..)
import Html.Attributes exposing (..)

import Url


import Data.InfoSysSummary exposing (InfoSysId)
import Data.InfoSystem as InfoSys exposing (InfoSystem)
import Api exposing (apiConfig)

import Page.InfoSystem.Form as Form
import Utils.Error.HttpError as HttpError
import Utils.Error.EditProblem as Problem

import Session.Session as Session
import Page.InfoSystem.Form exposing (infoSys2Form)



{-| Editing request flow

* from the list view is clicked the Edit link, so a message is sent to the runtime with an underlying URL that must be matched from the Route module
* the runtime react by sending the `Url` with a `LinkClicked` msg to the Main.update
* Main.update ask `Nav.pushUrl` to create **a command** for changing the URL in browser's address bar
* the Nav.pushUrl return a command for changing the address bar
* the runtime react converting the URL to a `Url` type and sending UrlChanged to Main.update
* the Main.update identify the corresponding Page and call the corresponding `initCurrentPage` and set the page in the Main.model
* the runtime react to the model chaing by calling Main.view
* the Main.view call the page.view trasforming the page messages to Main Msg and return the view to the runtime
* the runtime render the page
-}

type alias Data = WebData InfoSystem

type alias Model =
    { session : Session.Model
    , infosys : Data
    , form : Form.Form
    , problems : List (Problem.Problem Form.ValidatedField)
    }



-- althought the Main can have the infosys record, it is reloaded from the Id 
-- to prevent the risk that other client app has already modified the record that we want to edit
init : InfoSysId -> Session.Model -> ( Model, Cmd Msg )
init isId session =
    ( initialModel session, fetchData session isId )

-- navKey will be used to navigate users to the list page after the data is saved.
initialModel :Session.Model -> Model
initialModel session =
    { session = session
    , infosys = RemoteData.Loading
    , form = Form.emptyForm
    , problems = []
    }


fetchData : Session.Model -> InfoSysId -> Cmd Msg
fetchData session isID =
  let
    url = 
      (Session.getApi session |> Url.toString) 
      ++ "info_system/" 
      ++ Data.InfoSysSummary.idToString isID
  in
  RemoteData.Http.getWithConfig (apiConfig session.session)
    url
    ISReceived InfoSys.decoder


type Msg
    = ISReceived (WebData InfoSystem) -- info system received
    -- | SaveIS
    -- input messages
    | FormMsg Form.Msg



update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
  let

    -- Helper function for `update`. Updates the form and returns Cmd.none.
    -- Useful for recording form fields!
    updateForm : (Form.Form -> Form.Form) -> ( Model, Cmd Msg )
    updateForm transform =
        ( { model | form = transform model.form }, Cmd.none )
  in
    case msg of

        ISReceived infosys ->
          case infosys of
              RemoteData.Success is ->                 
                ( { model 
                  | infosys = infosys 
                  , form = Form.infoSys2Form is
                  }
                , Cmd.none 
                )
              _ ->
                ( { model 
                  | infosys = infosys 
                  }
                , Cmd.none 
                )

        

        ------ form input
        FormMsg formMsg ->
          case formMsg of
              Form.EnteredName val ->
                updateForm (\form -> { form | name = val }) 

              Form.EnteredDescription val ->
                  updateForm (\form -> { form | description = val }) 

              Form.EnteredFinality val ->
                  updateForm (\form -> { form | finality = val }) 
              
              Form.EnteredPassUrl val ->
                  updateForm (\form -> { form | passUrl = val }) 

              Form.EnteredRespEmail val ->
                  updateForm (\form -> { form | respEmail = val }) 

              Form.EnteredRespInfEmail val ->
                  updateForm (\form -> { form | respInfEmail = val }) 

              Form.SubmittedForm ->
                case Form.validate model.form of
                    Ok validForm ->
                        ( { model | problems = [] }
                        , submit model.session validForm
                        )

                    Err problems ->
                        ( { model | problems = problems }
                        , Cmd.none
                        )
        -- _ -> (model, Cmd.none)


----- SAVE

submit : Session.Model -> Form.TrimmedForm -> Cmd Msg
submit session f =
    case Session.viewer session.session of
      Just _ -> 
        RemoteData.Http.patchWithConfig 
          (Api.qryWithRepresentationConfig session.session)-- optimization possible with Postgres
          ((Session.getApi session |> Url.toString ) ++ "/info_system")
          ISReceived InfoSys.decoder (InfoSys.encoder <| Form.form2infoSys f)

      Nothing ->
        Cmd.none




----- VIEW            



view : Model -> Html Msg
view model =
    div []
        [ h3 [] [ text "Modifica Sistema" ]
        , viewIS model.infosys
        ]


viewIS : Data -> Html Msg
viewIS is =
    case is of
        RemoteData.NotAsked ->
            text ""

        RemoteData.Loading ->
            h3 [] [ text "Caricamento del sistema in corso..." ]

        RemoteData.Success isData ->
            Form.viewForm FormMsg <| infoSys2Form isData

        RemoteData.Failure httpError ->
            viewFetchError (HttpError.buildErrorMessage httpError)

viewFetchError : String -> Html Msg
viewFetchError errorMessage =
    let
        errorHeading =
            "Non posso caricare i sistemi al momento"
    in
    div []
        [ h3 [] [ text errorHeading ]
        , text ("Errore: " ++ errorMessage)
        ]

