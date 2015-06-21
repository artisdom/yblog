--------------------------------------------------------------------------------
{-# LANGUAGE OverloadedStrings #-}
import           Control.Monad          (forM)
import           Data.Monoid            ((<>),mconcat)
import           Hakyll

import           Data.List              (sortBy,isInfixOf)
import           Data.Ord               (comparing)
import           System.Locale          (defaultTimeLocale)

import           Abbreviations          (abbreviationFilter)
import           YFilters               (blogImage,blogFigure
                                        ,frenchPunctuation,highlight)
import           Multilang              (multiContext)
import           System.FilePath.Posix  (takeBaseName,takeDirectory,(</>),splitFileName)
import           Control.Monad          (forM_)

import           Config                 (langs,feedConfiguration)

--------------------------------------------------------------------------------
main :: IO ()
main = hakyll $ do
    match (     "Scratch/img/**"
          .||.  "Scratch/js/**"
          .||.  "Scratch/css/fonts/*"
          .||.  "Scratch/*/blog/*/**"
          .||.  "Scratch/files/**"
          .||.  "YBlog/**"
          .||.  "YPassword/**"
          .||.  "cv/**"
          .||.  "CNAME")
      staticBehavior

    -- -- Compressed SASS (add potentially included files)
    -- sassDependencies <- makePatternDependency "Scratch/css/include/*.sass"
    -- rulesExtraDependencies [sassDependencies] $ do
    match "Scratch/css/*" $ do
            route   $ setExtension "css"
            compile $ getResourceString >>=
                      withItemBody (unixFilter "sass" ["--trace"]) >>=
                      return . fmap compressCss

    -- Blog posts
    match "Scratch/*/blog/*.md" markdownPostBehavior

    -- Blog posts with html extension
    match "Scratch/*/blog/*.html" htmlPostBehavior

    -- for each language
    forM_ langs $ \lang -> do
      -- Archives
      match (fromGlob $ "Scratch/"++lang++"/blog.md") (archiveBehavior lang)
      -- RSS
      create [fromFilePath ("Scratch/"++lang++"/blog/feed/feed.xml")] (feedBehavior lang)

    -- Basic files
    match ("Scratch/*/*.md"
          .||. "Scratch/*/about/*.md"
          .||. "Scratch/*/softwares/*.md"
          .||. "Scratch/*/softwares/ypassword/*.md" ) markdownBehavior
    match "404.md" markdownBehaviorWithSimpleRoute

    -- Homepage
    match "index.html" $ do
        route idRoute
        compile $ do
            let indexCtx =
                 yContext <>
                  (mconcat $ map (\lang -> field (lang ++ "posts") $ \_->homePostList lang createdFirst) langs)
            getResourceBody
                >>= applyAsTemplate indexCtx
                >>= loadAndApplyTemplate "templates/boilerplate.html" indexCtx
                >>= relativizeUrls
                >>= removeIndexHtml

    match "templates/*" $ compile templateCompiler

--------------------------------------------------------------------------------
--
-- replace url of the form foo/bar/index.html by foo/bar
removeIndexHtml :: Item String -> Compiler (Item String)
removeIndexHtml item = return $ fmap (withUrls removeIndexStr) item

removeIndexStr :: String -> String
removeIndexStr url = case splitFileName url of
    (dir, "index.html") | isLocal dir -> dir
                        | otherwise   -> url
    _                                 -> url
    where isLocal uri = not (isInfixOf "://" uri)

--------------------------------------------------------------------------------
--
-- replace a foo/bar.md by foo/bar/index.html
-- this way the url looks like: foo/bar in most browsers
niceRoute :: Routes
niceRoute = customRoute createIndexRoute
  where
    createIndexRoute ident = takeDirectory p </> takeBaseName p </> "index.html"
                             where p=toFilePath ident

--------------------------------------------------------------------------------
--
-- Simply copy in the right place
staticBehavior :: Rules ()
staticBehavior = do
  route   idRoute
  compile copyFileCompiler

--------------------------------------------------------------------------------
applyFilter :: (Monad m, Functor f) => (String -> String) -> f String -> m (f String)
applyFilter transformator str = return $ (fmap $ transformator) str

--------------------------------------------------------------------------------
htmlPostBehavior :: Rules ()
htmlPostBehavior = do
  route $ niceRoute
  compile $ getResourceBody
        >>= applyFilter (abbreviationFilter . frenchPunctuation . highlight)
        >>= saveSnapshot "content"
        >>= loadAndApplyTemplate "templates/post.html" yPostContext
        >>= loadAndApplyTemplate "templates/boilerplate.html" yPostContext
        >>= relativizeUrls
        >>= removeIndexHtml

--------------------------------------------------------------------------------
preFilters :: String -> String -> String
preFilters itemPath =   abbreviationFilter
                      . blogImage itemName
                      . blogFigure itemName
                      where
                        itemName = takeBaseName itemPath

--------------------------------------------------------------------------------
postFilters :: String -> String
postFilters = frenchPunctuation . highlight

--------------------------------------------------------------------------------
--
-- change the extension to html
-- prefilter the markdown
-- apply pandoc (markdown -> html)
-- postfilter the html
-- apply templates posts then default then relitivize url
markdownBehavior :: Rules ()
markdownBehavior = do
  route $ niceRoute
  compile $ do
    body <- getResourceBody
    identifier <- getUnderlying
    return $ renderPandoc (fmap (preFilters (toFilePath identifier)) body)
    >>= applyFilter postFilters
    >>= loadAndApplyTemplate "templates/default.html" yContext
    >>= loadAndApplyTemplate "templates/boilerplate.html" yContext
    >>= relativizeUrls
    >>= removeIndexHtml

markdownBehaviorWithSimpleRoute :: Rules ()
markdownBehaviorWithSimpleRoute = do
  route $ setExtension "html"
  compile $ do
    body <- getResourceBody
    identifier <- getUnderlying
    return $ renderPandoc (fmap (preFilters (toFilePath identifier)) body)
    >>= applyFilter postFilters
    >>= loadAndApplyTemplate "templates/default.html"    yContext
    >>= loadAndApplyTemplate "templates/boilerplate.html" yContext
    >>= removeIndexHtml

--------------------------------------------------------------------------------
-- change the extension to html
-- prefilter the markdown
-- apply pandoc (markdown -> html)
-- postfilter the html
-- apply templates posts then default then relitivize url
markdownPostBehavior :: Rules ()
markdownPostBehavior = do
  route $ niceRoute
  compile $ do
    body <- getResourceBody
    identifier <- getUnderlying
    prefilteredText <- return $ (fmap (preFilters (toFilePath identifier)) body)
    return $ renderPandoc prefilteredText
    >>= applyFilter postFilters
    >>= saveSnapshot "content"
    >>= loadAndApplyTemplate "templates/post.html"    yPostContext
    >>= loadAndApplyTemplate "templates/boilerplate.html" yPostContext
    >>= relativizeUrls
    >>= removeIndexHtml

--------------------------------------------------------------------------------
archiveBehavior :: String -> Rules ()
archiveBehavior language = do
  route $ niceRoute
  compile $ do
    body <- getResourceBody
    identifier <- getUnderlying
    return $ renderPandoc (fmap (preFilters (toFilePath identifier)) body)
    >>= applyFilter postFilters
    >>= loadAndApplyTemplate "templates/archive.html" archiveCtx
    >>= loadAndApplyTemplate "templates/default.html" archiveCtx
    >>= loadAndApplyTemplate "templates/boilerplate.html" archiveCtx
    >>= relativizeUrls
    >>= removeIndexHtml
  where
    archiveCtx =
      field "posts" (\_ -> postList language createdFirst) <>
      yContext

--------------------------------------------------------------------------------
yContext :: Context String
yContext =  constField "type" "default" <>
            metaKeywordContext <>
            shortLinkContext <>
            multiContext <>
            imageContext <>
            prefixContext <>
            defaultContext

--------------------------------------------------------------------------------
yPostContext :: Context String
yPostContext =  constField "type" "article" <>
                metaKeywordContext <>
                subtitleContext <>
                shortLinkContext <>
                multiContext <>
                imageContext <>
                prefixContext <>
               defaultContext

--------------------------------------------------------------------------------
shortLinkContext :: Context String
shortLinkContext = field "shorturl" $
                    fmap (maybe "" (removeIndexStr . toUrl)) .getRoute . itemIdentifier

--------------------------------------------------------------------------------
prefixContext :: Context String
prefixContext = field "webprefix" $ \_ -> return $ "/Scratch"

--------------------------------------------------------------------------------
imageContext :: Context a
imageContext = field "image" $ \item -> do
  image <- getMetadataField (itemIdentifier item) "image"
  return $ maybe "/Scratch/img/presentation.png" id image


--------------------------------------------------------------------------------
metaKeywordContext :: Context String
metaKeywordContext = field "metaKeywords" $ \item -> do
  tags <- getMetadataField (itemIdentifier item) "tags"
  return $ maybe "" showMetaTags tags
    where
      showMetaTags t = "<meta name=\"keywords\" content=\"" ++ t ++ "\"/>\n"

--------------------------------------------------------------------------------
subtitleContext :: Context String
subtitleContext = field "subtitleTitle" $ \item -> do
  subt <- getMetadataField (itemIdentifier item) "subtitle"
  return $ maybe "" showSubtitle subt
    where
      showSubtitle t = "<h2>" ++ t ++ "</h2>\n"

--------------------------------------------------------------------------------
createdFirst :: [Item String] -> Compiler [Item String]
createdFirst items = do
  itemsWithTime <- forM items $ \item -> do
    utc <- getItemUTC defaultTimeLocale $ itemIdentifier item
    return (utc,item)
  return $ map snd $ reverse $ sortBy (comparing fst) itemsWithTime

--------------------------------------------------------------------------------
feedBehavior :: String -> Rules ()
feedBehavior language = do
      route idRoute
      compile $ do
        loadAllSnapshots (fromGlob $ "Scratch/" ++ language ++ "/blog/*") "content"
        >>= (fmap (take 10)) . createdFirst
        >>= renderAtom feedConfiguration feedCtx
      where
        feedCtx :: Context String
        feedCtx = mconcat [bodyField "description", yContext]

--------------------------------------------------------------------------------
--
-- load a list of Item but remove their body
lightLoadAll :: Pattern -> Compiler [Item String]
lightLoadAll pattern = do
  identifers <- getMatches pattern
  return [Item identifier "" | identifier <- identifers]
--------------------------------------------------------------------------------
postList :: String -> ([Item String] -> Compiler [Item String]) -> Compiler String
postList language sortFilter = do
    posts   <- lightLoadAll (fromGlob $ "Scratch/" ++ language ++ "/blog/*") >>= sortFilter
    itemTpl <- loadBody "templates/post-item.html"
    list    <- applyTemplateList itemTpl yContext posts
    return list

--------------------------------------------------------------------------------
homePostList :: String -> ([Item String] -> Compiler [Item String]) -> Compiler String
homePostList language sortFilter = do
    posts   <- lightLoadAll (fromGlob $ "Scratch/" ++ language ++ "/blog/*") >>= sortFilter
    itemTpl <- loadBody "templates/home-post-item.html"
    list    <- applyTemplateList itemTpl yContext (take 3 posts)
    return list
