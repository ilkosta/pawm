module Utils.Email exposing (..)

import Json.Decode as Decode exposing (Decoder)
import Email
import Html exposing (a)

import Utils.Json 

emailDecoder : Decoder Email.Email
emailDecoder = 
  Utils.Json.maybeDecoder Decode.string Email.fromString

emptyEmail : Email.Email
emptyEmail = 
  { localPart = ""
  , tags = []
  , domain = ""
  , tld = []
  }