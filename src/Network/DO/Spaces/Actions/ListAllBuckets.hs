{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE RecordWildCards #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE StrictData #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE UndecidableInstances #-}

-- |
module Network.DO.Spaces.Actions.ListAllBuckets
    ( ListAllBuckets(..)
    , ListAllBucketsResponse(..)
    ) where

import           Control.Monad.Reader    ( MonadReader(ask) )

import           Data.Coerce             ( coerce )
import           Data.Sequence           ( Seq )
import qualified Data.Sequence           as S

import           GHC.Generics            ( Generic )

import           Network.DO.Spaces.Types
                 ( Action(..)
                 , Bucket(Bucket)
                 , BucketInfo(..)
                 , MonadSpaces
                 , Owner(..)
                 , SpacesRequestBuilder(..)
                 )
import           Network.DO.Spaces.Utils
                 ( ownerP
                 , xmlAttrError
                 , xmlDocCursor
                 , xmlUTCTimeP
                 )

import qualified Text.XML.Cursor         as X
import           Text.XML.Cursor         ( ($/), (&/), (&|) )

data ListAllBuckets = ListAllBuckets
    deriving ( Show, Eq, Generic )

data ListAllBucketsResponse =
    ListAllBucketsResponse { owner :: Owner, buckets :: Seq BucketInfo }
    deriving ( Show, Eq, Generic )

instance MonadSpaces m => Action m ListAllBuckets where
    type SpacesResponse ListAllBuckets = ListAllBucketsResponse

    buildRequest _ = do
        spaces <- ask
        return SpacesRequestBuilder
               { body           = Nothing
               , method         = Nothing
               , object         = Nothing
               , queryString    = Nothing
               , bucket         = Nothing
               , headers        = mempty
               , overrideRegion = Nothing
               , ..
               }

    consumeResponse raw = do
        cursor <- xmlDocCursor raw
        owner <- X.forceM (xmlAttrError "Owner")
            $ cursor $/ X.laxElement "Owner" &| ownerP
        buckets <- S.fromList
            <$> (sequence $ cursor $/ X.laxElement "Buckets" &| bucketsP)
        return ListAllBucketsResponse { .. }
      where
        bucketsP c = X.forceM (xmlAttrError "Bucket")
            $ c $/ X.laxElement "Bucket" &| bucketInfoP

        bucketInfoP c = do
            name <- X.force (xmlAttrError "Name")
                $ c $/ X.laxElement "Name" &/ X.content &| coerce
            creationDate <- X.forceM (xmlAttrError "Creation date")
                $ c $/ X.laxElement "CreationDate" &/ X.content &| xmlUTCTimeP
            return BucketInfo { .. }
