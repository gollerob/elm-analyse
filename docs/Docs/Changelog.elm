module Docs.Changelog exposing (Model, Msg, init, update, view)

import Html exposing (..)
import RemoteData as RD exposing (RemoteData)
import Http
import Markdown
import Docs.Html as DocsHtml


type Model
    = Model (RemoteData Http.Error String)


type Msg
    = OnResponse (Result Http.Error String)


init : ( Model, Cmd Msg )
init =
    ( Model RD.Loading
    , loadChangelog
    )


loadChangelog : Cmd Msg
loadChangelog =
    Http.getString "https://raw.githubusercontent.com/stil4m/elm-analyse/master/CHANGELOG.md"
        |> Http.send OnResponse


update : Msg -> Model -> Model
update (OnResponse x) _ =
    Model (RD.fromResult x)


view : Model -> Html Msg
view (Model model) =
    DocsHtml.content
        [ case model of
            RD.Loading ->
                text "Loading..."

            RD.Success x ->
                Markdown.toHtml [] x

            RD.Failure _ ->
                text "Something went wrong"

            RD.NotAsked ->
                div [] []
        ]
