module Analyser.Checks.ImportAll exposing (checker)

import Elm.Syntax.Module exposing (..)
import Elm.Syntax.Base exposing (..)
import Analyser.FileContext exposing (FileContext)
import Analyser.Messages.Types exposing (Message, MessageData(ImportAll), newMessage)
import ASTUtil.Inspector as Inspector exposing (defaultConfig, Order(Post))
import Analyser.Configuration exposing (Configuration)
import Analyser.Checks.Base exposing (Checker, keyBasedChecker)
import Elm.Syntax.Exposing exposing (..)
import Analyser.Messages.Range as Range exposing (Range, RangeContext)


checker : Checker
checker =
    { check = scan
    , shouldCheck = keyBasedChecker [ "ImportAll" ]
    }


type alias ExposeAllContext =
    List ( ModuleName, Range )


scan : RangeContext -> FileContext -> Configuration -> List Message
scan rangeContext fileContext _ =
    Inspector.inspect
        { defaultConfig | onImport = Post (onImport rangeContext) }
        fileContext.ast
        []
        |> List.sortWith (\( _, a ) ( _, b ) -> Range.orderByStart a b)
        |> List.map (uncurry (ImportAll fileContext.path))
        |> List.map (newMessage [ ( fileContext.sha1, fileContext.path ) ])


onImport : RangeContext -> Import -> ExposeAllContext -> ExposeAllContext
onImport rangeContext imp context =
    flip List.append context <|
        case imp.exposingList of
            All range ->
                [ ( imp.moduleName, Range.build rangeContext range ) ]

            None ->
                []

            Explicit explicitList ->
                explicitList
                    |> List.filterMap
                        (\explicitItem ->
                            case explicitItem of
                                TypeExpose exposedType ->
                                    case exposedType.constructors of
                                        All range ->
                                            Just ( imp.moduleName, Range.build rangeContext range )

                                        _ ->
                                            Nothing

                                _ ->
                                    Nothing
                        )
