-- SPDX-FileCopyrightText: 2026 Mika Tammi
-- SPDX-License-Identifier: MIT
{-# LANGUAGE OverloadedStrings #-}

import Data.List (isInfixOf)
import Hakyll
import System.Directory qualified
import System.Exit qualified

main :: IO ()
main = do
  -- hakyllWith calls exitWith and never returns, which prevented
  -- a post-process pass from running after the build. Use
  -- hakyllWithExitCode to get the exit code back as a value, run
  -- the post-process, then exit.
  exitCode <- hakyllWithExitCode config rules
  injectBrandPostProcess "docs/index.html"
  System.Exit.exitWith exitCode

{- | After Hakyll has finished writing @docs/index.html@, splice the
corner brand link in just before @\</body\>@ if it isn't there
already. Idempotent — repeated invocations are no-ops.
-}
injectBrandPostProcess :: FilePath -> IO ()
injectBrandPostProcess path = do
  exists <- System.Directory.doesFileExist path
  if not exists
    then pure ()
    else do
      -- Read fully into memory before re-opening the path for
      -- write. `length html` walks the lazy-String spine, which
      -- exhausts and closes the read handle.
      html <- readFile path
      let !_ = length html
      if "brand-link" `isInfixOf` html
        then pure ()
        else writeFile path (injectBeforeBodyClose brandHtml html)

rules :: Rules ()
rules = do
  match "assets/images/**" $ do
    route idRoute
    compile copyFileCompiler

  match "assets/css/**" $ do
    route idRoute
    compile copyFileCompiler

  -- Render Graphviz .dot files to SVG via the `dot` CLI.
  match "assets/diagrams/*.dot" $ do
    route $ setExtension "svg"
    compile $
      getResourceString
        >>= withItemBody (unixFilter "dot" ["-Tsvg"])

  -- SLIDES.md → pandoc DZSlides → splice in the corner brand HTML.
  -- The brand HTML is an inline Haskell string constant
  -- (`brandHtml`) so there is no file-system dependency and no
  -- chance of a stale Hakyll cache hiding it. To change the
  -- brand, edit `brandHtml` below.
  match "SLIDES.md" $ do
    route $ constRoute "index.html"
    compile $
      getResourceBody
        >>= withItemBody
          ( unixFilter
              "pandoc"
              [ "-f"
              , "markdown"
              , "-t"
              , "dzslides"
              , "-s"
              , "--slide-level=2"
              , "--highlight-style=zenburn"
              , "--css=assets/css/overrides.css"
              ]
          )

{- | The bottom-right corner brand link. Lives in site.hs (not a
separate file) so any reference to a "stale include" can never
come back. Edit and re-run `cabal build` to change the link.
-}
brandHtml :: String
brandHtml =
  "<a class=\"brand-link\" \
  \href=\"https://purefun.fi\" target=\"_blank\" \
  \rel=\"noopener noreferrer\">https://purefun.fi</a>"

{- | Insert the corner-brand HTML immediately before the closing
@\</body\>@ tag in pandoc's DZSlides output. If for any reason
@\</body\>@ is missing, append the brand at the end so the link
still ships.
-}
injectBeforeBodyClose :: String -> String -> String
injectBeforeBodyClose brand html
  | "</body>" `isInfixOf` html = replaceFirst "</body>" (brand ++ "\n</body>") html
  | otherwise = html ++ "\n" ++ brand

-- | First-occurrence substring replacement.
replaceFirst :: String -> String -> String -> String
replaceFirst _ _ [] = []
replaceFirst needle replacement haystack@(c : rest)
  | take (length needle) haystack == needle =
      replacement ++ drop (length needle) haystack
  | otherwise = c : replaceFirst needle replacement rest

config :: Configuration
config =
  defaultConfiguration
    { destinationDirectory = "docs"
    , storeDirectory = "_cache"
    , tmpDirectory = "_cache/tmp"
    }
