module Data.User exposing (User, UserID(..), userID, decode)

import Json.Decode as JD
import Email 
import Utils.Email exposing (emailDecoder)



-- Optional, but recommended to have a type that
-- represents your primary key.


type UserID
    = UserID String



-- And a way to unwrap it...


userID : UserID -> String
userID (UserID id) =
    id



-- Define the record you would fetch back from the server.


type alias User =
    { id : UserID
    , email : Email.Email
    }


decode : JD.Decoder User
decode =
    JD.map2 User
        (JD.field "UserID" <| JD.map UserID JD.string)
        (JD.field "email" emailDecoder)
