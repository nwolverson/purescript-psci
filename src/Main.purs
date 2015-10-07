module Main where

import Prelude

import Data.Maybe
import Data.String (indexOf)
import Data.Foldable (intercalate)

import Control.Monad.Eff
import Control.Monad.Eff.Ref
import Control.Monad.Eff.Console

import Node.FS.Sync (writeTextFile)
import Node.Encoding (Encoding(UTF8))
import Node.ReadLine

foreign import data PROCESS :: !

foreign import psc :: forall a b eff. Array String -> Eff (process :: PROCESS | eff) a -> Eff (process :: PROCESS | eff) b -> Eff (process :: PROCESS | eff) Unit

foreign import execModule :: forall a eff. String -> Eff (process :: PROCESS | eff) a -> Eff (process :: PROCESS | eff) Unit

type PSCiState =
  { imports :: Array String
  }

initialState :: PSCiState
initialState = { imports: [] }

main :: Eff _ Unit
main = void do
  state <- newRef initialState
  interface <- createInterface noCompletion

  log $ intercalate "\n"
    [ " ____  ____   ____ _ "
    , "|  _ \\/ ___| / ___(_)"
    , "| |_) \\___ \\| |   | |"
    , "|  __/ ___) | |___| |"
    , "|_|   |____/ \\____|_|"
    ]

  let createModule :: forall eff. String -> Eff (process :: PROCESS, ref :: REF | eff) String
      createModule expr = do
        { imports: imports } <- readRef state
        return $ intercalate "\n" $
          [ "module PSCI.Main where" ] ++
          imports ++
          [ "main = Control.Monad.Eff.Console.print (" ++ expr ++ ")" ]

      handle :: forall a eff. String -> Eff _ Unit
      handle s =
        case indexOf "import" s of
          Just 0 -> void do
            modifyRef state (\st -> st { imports = st.imports ++ [s] })
            prompt interface
          _ -> do
            src <- createModule s
            writeTextFile UTF8 ".psci.purs" src
            psc [ "./bower_components/purescript-*/src/**/*.*", "./src/**/*.*", ".psci.purs" ] do
                execModule "PSCI.Main" do
                  prompt interface
              $ prompt interface

  setPrompt "> " 2 interface
  prompt interface
  setLineHandler interface $ \s ->
    if s == ":q"
       then void $ close interface
       else handle s
