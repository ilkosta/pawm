module Page.InfoSystem.New exposing (Model,Msg,view,init,update,subscriptions)


import RemoteData.Http
import RemoteData exposing (WebData)

import Html exposing (..)
import Html.Attributes exposing (..)

import Url


import Data.InfoSysSummary exposing (InfoSysId)
import Data.InfoSystem as InfoSys exposing (InfoSystem)
import Api exposing (apiConfig)

import Page.InfoSystem.Form as Form

import Utils.Error.EditProblem as Problem
import Route
import Session.Session as Session
import Page.InfoSystem.Form exposing (infoSys2Form)
import Data.InfoSysSummary as InfoSysSummary 
import InfoSysSummary

import Postgrest.Queries as Q
import SingleSelect
import Utils.UI
import Data.Person
import Data.Person exposing (Person)
import Email
import Route
import Data.UO exposing (UO)


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
    , form : Form.Form
    , problems : List (Problem.Problem Form.ValidatedField)
    }


type Msg
    = ISSaved (WebData InfoSystem)
    -- input messages
    | FormMsg Form.Msg


-- althought the Main can have the infosys record, it is reloaded from the Id 
-- to prevent the risk that other client app has already modified the record that we want to edit
init : Session.Model -> ( Model, Cmd Msg )
init session =
    ( initialModel session
    , List.map (Cmd.map FormMsg) 
        [ Form.fetchPeople {session = session} 
        , Form.fetchUO {session = session} ]
      |> Cmd.batch
    )


initialModel :Session.Model -> Model
initialModel session =
    { session = session
    , form = Form.emptyForm
    , problems = []
    }


view : Model -> Html Msg
view model =
  let
    h = h3 [] [ text "Inserimento Nuovo Sistema"]
  in
    div [] (h :: (viewIS model))
        


viewIS : Model -> List (Html Msg)
viewIS model =
  [Form.view FormMsg model]



update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
  let
    -- Helper function for `update`. Updates the form and returns Cmd.none.
    -- Useful for recording form fields!
    updateForm : (Form.Form -> Form.Form) -> Cmd Msg -> ( Model, Cmd Msg )
    updateForm transform cmd =
        ( { model | form = transform model.form }, cmd )
  in
    case msg of

        ISSaved data ->
          case data of
            RemoteData.Success _ -> 
              ( model
              , Session.navKey model.session.session
                |> Route.pushUrl Route.ISList 
              )
            _ -> 
              let _ = Debug.log "stato non previsto in fase di salvataggio" in 
              (model,Cmd.none)


        ------ form input
        FormMsg formMsg ->
          case formMsg of
              Form.EnteredName val ->
                updateForm (\form -> { form | name = val }) Cmd.none

              Form.EnteredDescription val ->
                  updateForm (\form -> { form | description = val }) Cmd.none

              Form.EnteredFinality val ->
                  updateForm (\form -> { form | finality = val })  Cmd.none
              
              Form.EnteredPassUrl val ->
                  updateForm (\form -> { form | passUrl = val })  Cmd.none

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
                        

              Form.HandlePeopleResponse data ->
                let
                  people =
                    case data of 
                      RemoteData.Success p -> 
                        RemoteData.Success (Data.Person.emptyPerson :: p)
                      _ -> data


                  peopleSel : String -> Maybe Person
                  peopleSel e = 
                    case data of
                      RemoteData.Success p ->
                        List.filter (\pers -> (Email.toString pers.email) == e ) p
                        |> List.head
                      _ -> Nothing

                  respSel = peopleSel model.form.respEmail
                  
                  respInfSel = peopleSel model.form.respInfEmail
                    
                in
                updateForm 
                  (\f -> 
                      { f 
                      | people = people 
                      , respSelected = respSel 
                      , respInfSelected = respInfSel
                      }
                  )
                  Cmd.none

              Form.HandleUOResponse data ->
                let
                  uoSel : Maybe UO
                  uoSel = 
                    case data of
                      RemoteData.Success uoList ->
                        List.filter (\uo -> uo.id == 154) uoList
                        |> List.head
                      _ -> Nothing
                   
                in
                updateForm 
                  (\f -> 
                      { f 
                      | uoList = data 
                      , uoSelected = uoSel
                      }
                  )
                  Cmd.none

              -----
              Form.HandleRespSelectUpdate sMsg ->
                let
                    ( updatedSelect, selectCmd ) =
                        SingleSelect.update sMsg 
                          -- (Api.peopleRemoteSearchAttrs model.session) 
                          model.form.respSelect
                in
                updateForm 
                  (\form -> { form | respSelect = updatedSelect })  
                  (selectCmd |> Cmd.map FormMsg)

              Form.HandleRespSelection ( person , sMsg ) ->
                let
                    ( updatedSelect, selectCmd ) =
                        SingleSelect.update sMsg 
                          -- (Api.peopleRemoteSearchAttrs model.session) 
                          model.form.respSelect
                in
                updateForm 
                  (\form -> 
                    { form 
                    | respSelected = Just person
                    , respSelect = updatedSelect })  
                  (selectCmd |> Cmd.map FormMsg)

              Form.HandleRespInfSelectUpdate sMsg ->
                let
                    ( updatedSelect, selectCmd ) =
                        SingleSelect.update sMsg 
                          -- (Api.peopleRemoteSearchAttrs model.session) 
                          model.form.respInfSelect
                in
                updateForm 
                  (\form -> { form | respInfSelect = updatedSelect })  
                  (selectCmd |> Cmd.map FormMsg)

              Form.HandleRespInfSelection ( person , sMsg ) ->
                let
                    ( updatedSelect, selectCmd ) =
                        SingleSelect.update sMsg 
                          -- (Api.peopleRemoteSearchAttrs model.session) 
                          model.form.respInfSelect
                in
                updateForm 
                  (\form -> 
                    { form 
                    | respInfSelected = Just person
                    , respInfSelect = updatedSelect })  
                  (selectCmd |> Cmd.map FormMsg)
              ----
              Form.HandleUOSelectUpdate sMsg ->
                let
                    ( updatedSelect, selectCmd ) =
                        SingleSelect.update sMsg 
                          -- (Api.peopleRemoteSearchAttrs model.session) 
                          model.form.uoSelect
                in
                updateForm 
                  (\form -> { form | uoSelect = updatedSelect })  
                  (selectCmd |> Cmd.map FormMsg)

              Form.HandleUOSelection ( uo , sMsg ) ->
                let
                    ( updatedSelect, selectCmd ) =
                        SingleSelect.update sMsg 
                          -- (Api.peopleRemoteSearchAttrs model.session) 
                          model.form.uoSelect
                in
                updateForm 
                  (\form -> 
                    { form 
                    | uoSelected = Just uo
                    , uoSelect = updatedSelect })  
                  (selectCmd |> Cmd.map FormMsg)


submit session f =
  let
    infosys = Form.form2infoSys f
    id = Maybe.map InfoSysSummary.idToInt infosys.id 
          |> Maybe.withDefault 0
    url = 
      (Session.getApi session |> Url.toString ) ++ "/info_system" 
      
    body = InfoSys.encoder infosys

    reqConfig = 
      apiConfig session.session
      |> Api.apiSingleResult
      |> Api.configWithRepresentation
      |> Api.apiConfigToRequestConfig
      
  in
    case Session.viewer session.session of
      Just _ -> 
        RemoteData.Http.postWithConfig reqConfig url
          ISSaved InfoSys.decoder body

      Nothing ->
        Cmd.none


{- The select module uses a subscription to determine when to close (outside of a selection) -}
subscriptions : Model -> Sub Msg
subscriptions model =
  List.map (Sub.map FormMsg)
    [ SingleSelect.subscriptions model.form.respSelect
    , SingleSelect.subscriptions model.form.respInfSelect
    , SingleSelect.subscriptions model.form.uoSelect
    ]
  |> Sub.batch                  