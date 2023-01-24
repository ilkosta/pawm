module Session.Viewer exposing 
  (Viewer, cred, decoder, userId, email, fullName )

{-| The logged-in user currently viewing this page. It stores enough data to
be able to render the menu bar (username etc.), along with Cred so it's
impossible to have a Viewer if you aren't logged in.
-}

import Session.Cred as Cred exposing (Cred)
-- import Utils.Email exposing (Email)
import Json.Decode as Decode exposing (Decoder)
-- import Username exposing (Username)
import Data.User as User
import Email
import Json.Decode.Pipeline exposing (custom, required)


-- TYPES


type Viewer
    = Viewer Cred



-- INFO


cred : Viewer -> Cred
cred (Viewer val) =
    val


userId : Viewer -> User.UserID
userId (Viewer val) =
    Cred.getUserId val

email  : Viewer -> Email.Email
email (Viewer val) = Cred.getEmail val


fullName  : Viewer -> String
fullName (Viewer val) = Cred.getFullName val


-- SERIALIZATION


decoder : Decoder (Cred -> Viewer)
decoder =
    Decode.succeed Viewer

-- store : Viewer -> Cmd msg
-- store (Viewer credVal) =
--     Api.storeCredWith
--         credVal

