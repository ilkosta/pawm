module Main exposing (main)

import Page.Home
import Browser exposing (Document, UrlRequest)
import Browser.Navigation as Nav
import Url exposing (Url)

import Json.Decode as Decode

import Html exposing (..)

import Page.InfoSystem.List as ListInfoSys
import Page.InfoSystem.Edit as ISEdit
import Page.InfoSystem.New  as ISNew
import Page.InfoSystem.Details as ISDetails

import Route exposing (Route)
import Session.Session as Session

import Api
import Utils.Url
import Page exposing (Page(..))

---  pages
import Page.NotFound
import Page.Home

-- import Screen


{-| NAVIGATION FLOW

after INIT FLOW

* the runtime intercept a msg from the specific page (es. change url)
* send the message to `update` where the internal link is converted to the `Url` type and added as a payload to the message
* the update ask to push the url to create a command for changing the url in the browser's address bar
* The browser notify the address bar change
* the runtime convert the new address in `Url` type and add it as a payload to `UrlChanged` message to `update`
* the update extract the route from the Url
* the update determine which page to display basend on the new route and store that in the page field
* the runtime see the model change and call `view`
...
-}

main : Program Decode.Value Model Msg
main =
    Browser.application
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        , onUrlRequest = LinkClicked
        , onUrlChange = UrlChanged
        }

type alias Model =
    { route : Route     -- current route
    , page : Page       -- current page
    , session : Session.Model
    -- , screen : Screen
    }


  

---- INIT

{-| INIT FLOW

* the Browser send the full URL entered by the user in address bar to the runtime
* the Runtime convert the full URL to the `Url` type and send it to `init`
* `init` extract the route from the `Url`
* determine which page to display based on the current route and store that in the page filed
* return a fully initialized main model to the runtime

`init` fn have two responsibilities:

* Initialize the main model
* Initialize the current page

For the first extract a route from url and store it in the route model field
For the second it call `initCurrentPage`
  -}
init : Decode.Value -> Url -> Nav.Key -> ( Model, Cmd Msg )
init flags url navKey =
    let

      viewer = 
        Decode.decodeValue (Decode.field "viewer" Api.viewerDecoder) flags    
        |> Result.toMaybe

      apiUrl = 
        Decode.decodeValue Session.apiUrlDecoder flags 
        |> Result.toMaybe
        |> Maybe.withDefault Utils.Url.emptyUrl

      session = Session.fromViewer apiUrl navKey viewer
      model =
          { route = Route.parseUrl url
          , page = NotFoundPage -- FIXME: antipattern: fallback to 404
          , session = session
          -- , screen = Screen
          }
    in
    initCurrentPage ( model, Cmd.none )    



{-| To properly manage the interaction between pages

     The Main module doesn’t handle any page specific messages. 
     It simply forwards them to the correct page module.

     The page commands are designed to send a page specific message after they are executed
     Although each page is capable of creating its own commands, it can’t fire them off to the Elm runtime. 
     That responsibility lies with the Main module.

     The Main module doesn't know the internal details of page command or msg
     It only know that the page manage some messages
     (see `initCurrentPage` comments for the Msg remapping/construction)
-}
type Msg
    = LinkClicked UrlRequest
    | UrlChanged Url
    | LoginMsg
    | LogoutMsg
    ---- js events
    | GotSession Session.Model
    ---- page events
    | ListPageMsg ListInfoSys.Msg
    | ISNewPageMsg ISNew.Msg
    | ISEditPageMsg ISEdit.Msg
    | ISDetailsPageMsg ISDetails.Msg
    



{-| Determine which page to display based on route.

    Takes the main model and any commands we may want to fire 
    when the app is being initialized, and 
    ask the page to return 
    * its model by calling its init function
    * a Main Msg data constructor remapped from the page Msg (see `Msg` comments)
-}
initCurrentPage : ( Model, Cmd Msg ) -> ( Model, Cmd Msg )
initCurrentPage ( model, existingCmds ) =
    let
        _ = Debug.log "sono nella initCurrentPage per " "."
        ( currentPage, mappedPageCmds ) =
          if Page.needAuth model.route && 
              Session.viewer model.session.session == Nothing
          then (model.page, Cmd.map (\_ -> LoginMsg ) Cmd.none)
          else
            case model.route of

                --- simple view pages --------
                Route.NotFound ->
                    ( NotFoundPage, Cmd.none )

                Route.Home ->
                  ( HomePage, Cmd.none )
                -----------------------------

                Route.ISList ->
                    let
                        ( pageModel, pageCmds ) =
                            ListInfoSys.init model.session
                    in
                    ( ListPage pageModel, Cmd.map ListPageMsg pageCmds )


                Route.ISDetails sysid ->
                    let
                        ( pageModel, pageCmds ) =
                            ISDetails.init sysid model.session
                    in
                    ( ISDetailsPage pageModel
                    , Cmd.map ISDetailsPageMsg pageCmds )


                Route.ISNew ->
                    let
                        ( pageModel, pageCmds ) =
                            ISNew.init model.session
                    in
                    ( ISNewPage pageModel, Cmd.map ISNewPageMsg pageCmds )


                Route.ISEdit sysid ->
                    let
                        ( pageModel, pageCmd ) =
                            ISEdit.init sysid model.session
                    in
                    ( ISEditPage pageModel, Cmd.map ISEditPageMsg pageCmd )

                -- _ -> ( NotFoundPage, Cmd.none )
                    
                
    in
    ( { model | page = currentPage }
    , Cmd.batch [ existingCmds, mappedPageCmds ]
    )    


---- VIEW the correct page

{-| VIEW FLOW

every time the runtime see a change on the model (ex. init flow)
it call the view

* the runtime get view code 
* the view code on Main call the view code on the specific page
* the page messages generated from html are transformed on main msg
* the view code is returned to the runtime 


  Delegate the reposibility for displaying the page to the specific page-view

  as with the page Commands encapsuletion in `initCurrentPage`
  here the messages produced by the Page Html are remapped Main Msg
-}
view : Model -> Document Msg
view model =
  let
    viewer = Session.viewer model.session.session
    viewPage = Page.viewPage (LoginMsg,LogoutMsg) viewer
  in
    case model.page of
        NotFoundPage ->
          viewPage NotFoundPage 
          { title = "mmm"
          , content = [Page.NotFound.view]
          }
          
        HomePage -> 
          viewPage HomePage
          { title = "Home"
          , content = [Page.Home.view]
          }

        ListPage pageModel ->
          viewPage (ListPage pageModel)
          { title = "Elenco Sistemi"
          , content =  [ ListInfoSys.view pageModel
                      |> Html.map ListPageMsg 
                    ]
          }

        ISNewPage pageModel ->
          viewPage (ISNewPage pageModel)
          { title = "Nuovo Sistema"
          , content = [ ISNew.view pageModel
                        |> Html.map ISNewPageMsg
                      ]
          }

        ISEditPage pageModel ->
          viewPage (ISEditPage pageModel)
          { title = "Modifica Sistema"
          , content =  [ ISEdit.view pageModel
                      |> Html.map ISEditPageMsg
                    ]                    
          }

        ISDetailsPage pageModel ->
          viewPage (ISDetailsPage pageModel)
          { title = "Info Sistema"
          , content =  [ ISDetails.view pageModel
                      |> Html.map ISDetailsPageMsg
                    ]                    
          }

---- UPDATE the page model   


{-| forward the responsibility for the update to the correct page

    The Main module isn’t responsible for updating page models. 
    That responsibility lies with page modules. 
    That’s why we need to call a page specific update function to get 
    an updated page model and a new list of page commands.

    The Page specfic Msg and Model are unwrapped by pattern matching with the Main Msg and Page
-}
update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case ( msg, model.page ) of
        -----------------------------
        -- generic navigation flow
        ( LinkClicked urlRequest, _ ) ->
            case urlRequest of
                -- internal: same protocol, host name, and port number
                Browser.Internal url ->
                  let
                    navkey = Session.navKey model.session.session
                    urlStr = Url.toString url
                  in
                    ( model
                    , Nav.pushUrl navkey urlStr
                    )

                Browser.External url ->
                    ( model
                    , Nav.load url
                    )

        ( UrlChanged url, _ ) ->
            let
                newRoute =
                    Route.parseUrl url
            in
            ( { model | route = newRoute }, Cmd.none )
                |> initCurrentPage

        (LogoutMsg, _) -> 
          ( Session.resetViewer model 
          , Cmd.batch [ 
              Api.logout () 
            , Route.pushUrl Route.Home <| Session.navKey model.session.session
            ] 
          )
        (LoginMsg, _) -> 
          let _ = Debug.log "sto gestendo il msg LoginMsg" "" in
          ( model
          , Cmd.batch 
            [ Api.login ()
            -- then return to the current page (pointed by `model.route`)
            , Route.pushUrl model.route <| Session.navKey model.session.session
            ]
          )
        -----------------------------
        ( GotSession session, _ ) ->
            -- forward the updated model.session 
            -- to the current model.page
            let
                updatePageSession : ({m | session : Session.Model} -> Page) -> {m | session : Session.Model} -> Page
                updatePageSession p m_ =
                  let
                     m = {m_ | session = session} 
                  in
                  p m

                updatedPage : Page
                updatedPage = 
                  case model.page of
                    ListPage    m -> updatePageSession ListPage   m
                    ISEditPage  m -> updatePageSession ISEditPage m
                    _ -> model.page

                
            in            
            ( {model | session = session , page = updatedPage }, Cmd.none) 
            
        -----------------------------
        -- page mapping

        -- list
        ( ListPageMsg subMsg, ListPage pageModel ) ->
            let
                ( updatedPageModel, updatedCmd ) =
                    ListInfoSys.update subMsg pageModel
            in
            ( { model | page = ListPage updatedPageModel }
            , Cmd.map ListPageMsg updatedCmd
            )

        -- new
        ( ISNewPageMsg subMsg, ISNewPage pageModel ) ->
            let
                ( updatedPageModel, updatedCmd ) =
                    ISNew.update subMsg pageModel
            in
            ( { model | page = ISNewPage updatedPageModel }
            , Cmd.map ISNewPageMsg updatedCmd
            )

        -- edit
        ( ISEditPageMsg subMsg, ISEditPage pageModel ) ->
            let
                ( updatedPageModel, updatedCmd ) =
                    ISEdit.update subMsg pageModel
            in
            ( { model | page = ISEditPage updatedPageModel }
            , Cmd.map ISEditPageMsg updatedCmd
            )

        -- details
        ( ISDetailsPageMsg subMsg, ISDetailsPage pageModel ) ->
            let
                ( updatedPageModel, updatedCmd ) =
                    ISDetails.update subMsg pageModel
            in
            ( { model | page = ISDetailsPage updatedPageModel }
            , Cmd.map ISDetailsPageMsg updatedCmd
            )
        -----------------------------

        

        ( _, _ ) -> -- FIXME: antipattern: hide compiler checks - maybe ok for initials fast iterations... 
            ( model, Cmd.none )




--- SUBSCRIPTION


{-| 
Subscriptions scope:

- listen to an event generated by a Javascript code
- encode the event to a message
- send the message to `update`

Subscriptions allow us to listen to external events such as incoming WebSocket messages, 
clock tick events, mouse/keyboard events, geolocation changes, 
and an output generated by a JavaScript library.

Subscription ask the Elm runtime to listen for the specified event 
and then send the corresponding message to update the model
-}

subscriptions : Model -> Sub Msg
subscriptions model = 
  let
      tokenUpdate msg = 
        Api.sessionChanges msg model.session 
          (Session.navKey model.session.session)
      
      pagesMgs = 
        case model.page of
          NotFoundPage ->
              Sub.none
          
          -- ListPage m -> 
          --   Sub.map ListPageMsg (ListInfoSys.subscriptions m)

          ISEditPage m ->
            Sub.map ISEditPageMsg (ISEdit.subscriptions m)
            
          _ -> Sub.none
  in
  
  Sub.batch
    [ tokenUpdate GotSession , pagesMgs]

  


