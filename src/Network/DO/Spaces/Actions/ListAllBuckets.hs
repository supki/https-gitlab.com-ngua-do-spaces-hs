{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DerivingStrategies #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE RecordWildCards #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE StrictData #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE UndecidableInstances #-}

-- |
-- Module      : Network.DO.Spaces.Actions.ListAllBuckets
-- Copyright   : (c) 2021 Rory Tyler Hayford
-- License     : BSD-3-Clause
-- Maintainer  : rory.hayford@protonmail.com
-- Stability   : experimental
-- Portability : GHC
--
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
import           Network.DO.Spaces.Utils

import qualified Text.XML.Cursor         as X
import           Text.XML.Cursor         ( ($/), (&/), (&|) )

-- | List all of your 'Bucket's withing the 'Network.DO.Spaces.Region' you have configured
data ListAllBuckets = ListAllBuckets
    deriving stock ( Show, Eq, Generic )

data ListAllBucketsResponse =
    ListAllBucketsResponse { owner :: Owner, buckets :: Seq BucketInfo }
    deriving stock ( Show, Eq, Generic )

instance MonadSpaces m => Action m ListAllBuckets where
    type ConsumedResponse ListAllBuckets = ListAllBucketsResponse

    buildRequest _ = do
        spaces <- ask
        pure SpacesRequestBuilder
             { body           = Nothing
             , method         = Nothing
             , object         = Nothing
             , queryString    = Nothing
             , subresources   = Nothing
             , bucket         = Nothing
             , headers        = mempty
             , overrideRegion = Nothing
             , ..
             }

    consumeResponse raw = do
        cursor <- xmlDocCursor raw
        owner <- X.forceM (xmlElemError "Owner")
            $ cursor $/ X.laxElement "Owner" &| ownerP
        bs <- X.force (xmlElemError "Buckets")
            $ cursor $/ X.laxElement "Buckets" &| bucketsP
        pure ListAllBucketsResponse { buckets = S.fromList bs, .. }
      where
        bucketsP c = X.forceM (xmlElemError "Bucket") . sequence
            $ c $/ X.laxElement "Bucket" &| bucketInfoP

        bucketInfoP c = do
            name <- X.force (xmlElemError "Name")
                $ c $/ X.laxElement "Name" &/ X.content &| coerce
            creationDate <- X.forceM (xmlElemError "Creation date")
                $ c $/ X.laxElement "CreationDate" &/ X.content &| xmlUTCTime
            pure BucketInfo { .. }
