import './main.css';
import { Elm } from './Main.elm';
import * as serviceWorker from './serviceWorker';
import { createClient } from '@supabase/supabase-js';

const storageKey = "sb-localhost-auth-token";

const api_host = "http://localhost:54321";
// const api_host = "https://localhost:3000";

const api_url = api_host + "/rest/v1/";
//const anon_key = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0";
const anon_key = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImV4cCI6MTk4MzgxMjk5Nn0.EGIM96RAZx35lJzdJsyH-qQwv8Hdp7fsn3W0YpN81IU";

const options = {
  schema: 'public',
  headers: { 'x-my-custom-header': 'ISI' },
  autoRefreshToken: true,
  persistSession: true,
  detectSessionInUrl: true,
  // Optional key name used for storing tokens in local storage.
  storageKey: storageKey
};

const supabase = createClient(
  api_host,
  // public anonymous key of the supabase project (from dashboard)
  anon_key,
  options
);




function getToken() {
  return JSON.parse(localStorage.getItem(storageKey));
}

// laoding of the localStorage at start up
function initElm() {
  let flags = { viewer: getToken(), api_url: api_url };
  console.log(`flags di inizializzazione: ${JSON.stringify(flags)}`);
  return Elm.Main.init({ node: document.getElementById('root'), flags: flags });
}


// const storageUO = "uo";
// const storageAddressBook = "address-book";

// loadResource(storageUO, "uo");
// loadResource(storageAddressBook, "address_book");

const app = initElm();


function renewToken() {

  let token = getToken();
  if (!token)
    return;

  let refresh_token = token.refresh_token;

  fetch(api_host + "/auth/v1/token?grant_type=refresh_token",
    {
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'apikey': anon_key
      },
      method: "POST",
      body: JSON.stringify({ refresh_token: refresh_token })
    })
    .then(function (res) {
      console.log("nuovo token:" + res);
      if (res.ok) {
        // store in localstorage
        localStorage.setItem(storageKey, token);
        // load in Elm the renewd token
        app.ports.onStoreChange.send(token);
    }

  })
    .catch(function (res) {
      console.error(res);
    });
}

var now = new Date().getTime();
if (getToken() && getToken().expires_at > now) {
  // `flags.expires_at` is float value representing the number of seconds since epoch into a Posix.
  // 300000 = 1000 millisecondi * 60 secondi * 5 minuti
  let renew_at = getToken().expires_at - 300000; // 5 minuti
  setTimeout(renewtoken, renew_at - now);
}





app.ports.login.subscribe(async () => {
  console.log("invoco login...");
  const { user, session, error } = await supabase.auth.signInWithOAuth({
    // provider can be 'github', 'google', 'gitlab', and more
    provider: 'google',
  });
  if (error) {
    let msgerr = "";
    if (error.response === undefined) {
      msgerr += "error from the auth server without error.response\n";
    } else {
      msgerr += `response from the auth server: ${error.response}\n`;
    }

    if (error.status === undefined) {
      msgerr += "error from the auth server without status code\n";
    } else {
      msgerr += `error from the auth server with the status code: ${error.status}\n`;
    }
    console.error(msgerr);
  }
});

app.ports.logout.subscribe(async () => {
  const { error } = await supabase.auth.signOut();
  if (error)
    console.error(error);
});

// If you want your app to work offline and load faster, you can change
// unregister() to register() below. Note this comes with some pitfalls.
// Learn more about service workers: https://bit.ly/CRA-PWA
serviceWorker.unregister();
// serviceWorker.register();



// const api_host = "http://192.168.1.13:54321"

// const api_host = "https://localhost:3000";
