module InfoSysDecoding exposing (..)

import Json.Decode exposing (decodeString)
import Test
import Expect
import Fuzz exposing (Fuzzer, int, list, string)

import Data.InfoSystem as InfoSys


-- import test

suite : Test.Test
suite =
  Test.describe "decodifica del token" [validRecDecoding]
  -- Test.test "prova" <| \_ -> Expect.pass

validRecDecoding : Test.Test
validRecDecoding = 
  let
    rec = """
      {"id":1,"description":"Project Assistant - Sistema di gestione dei progetti digitali","finality":null,"uo_id":154,"pass_url":"https://pass.regione.marche.it/projects/pass","name":"pass","resp_email":"costantino.giuliodori@regione.marche.it","resp_inf_email":null}
    """
  in
    Test.test "decodifica di un record infosys" <| 
      \_ -> case decodeString InfoSys.decoder rec of
          Ok _ ->
            Expect.pass

          Err _ ->
            Expect.fail "Failed to decode the record"

