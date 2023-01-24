module Session.Cred exposing 
  ( Cred
  , getUserId, getEmail, getFullName
  , decoder
  )


{-| The authentication credentials for the Viewer (that is, the currently logged-in user.)

This mainly includes:

  - The cred's Username
  - The cred's authentication token

By design, there is no way to access the token directly as a String.
It may be encoded for persistence (not yet implemented), and it can be added to a header
to a HttpBuilder for a request, but that's it.

This token should never be rendered to the end user, and with this API, it
can't be!

-}

import Json.Decode as JD
import Email
import Utils.Email exposing (emailDecoder)

import Data.User as User exposing (UserID)

type Cred
    -- = Cred UserID String String -- userid, email, token
    = Cred CredData

type alias CredData = 
  { uid: User.UserID
  , email : Email.Email
  , token : String
  , fullName : String
  }

getUserId : Cred -> UserID
getUserId (Cred {uid}) =  uid

getEmail : Cred -> Email.Email
getEmail (Cred {email}) = email

getFullName : Cred -> String
getFullName (Cred {fullName}) = fullName

{-| It's important that this is never exposed!

We expose `login` and `application` instead, so we can be certain that if anyone
ever has access to a `Cred` value, it came from either the login API endpoint
or was passed in via flags.

NOTE: never expose `credDecoder`
-}
decoder : JD.Decoder Cred
decoder =
  let
      userIdDecoder = JD.field "user" <|  JD.field "id" JD.string
      emailDecoder =  JD.field "user" <|  JD.field "email" Utils.Email.emailDecoder
      tokenDecoder =  JD.field "access_token" JD.string

      fullNameDecoder = 
        JD.field "user" 
        <| JD.field "user_metadata" 
        <|  JD.field "full_name" JD.string
  in
   
  JD.map4 CredData
        (JD.map User.UserID userIdDecoder)
        emailDecoder
        tokenDecoder
        fullNameDecoder
    |> JD.map Cred

