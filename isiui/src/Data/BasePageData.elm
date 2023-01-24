module Data.BasePageData exposing (..)

import Session.Session as Session
import Utils.Error.LoadingProblem  as Problem
import RemoteData exposing (WebData)

type alias BaseDataModel a = 
  { data : WebData a
  , session : Session.Model
  , problems : List Problem.Problem
  }

init : Session.Model -> (BaseDataModel a, Cmd msg )  
init session = 
  ( { data = RemoteData.NotAsked
    , session = session
    , problems = []
    }
  , Cmd.none
  )