{-# LANGUAGE DataKinds #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DuplicateRecordFields #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE RecordWildCards #-}
{-# LANGUAGE StrictData #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE UndecidableInstances #-}

-- |
module Network.DO.Spaces.Actions.GetObject
    ( GetObject(..)
    , GetObjectResponse(..)
    ) where

import           Conduit                 ( (.|), runConduit )

import           Control.Monad.Reader    ( MonadReader(ask) )

import qualified Data.ByteString.Lazy    as LB
import           Data.Conduit.Binary     ( sinkLbs )

import           GHC.Generics            ( Generic )

import           Network.DO.Spaces.Types
                 ( Action(..)
                 , Bucket
                 , MonadSpaces
                 , Object
                 , ObjectMetadata
                 , RawResponse(..)
                 , SpacesRequestBuilder(..)
                 )
import           Network.DO.Spaces.Utils ( getObjectMetadata )

-- | Retrieve an 'Object' along with its associated metadata. The object's data
-- is read into a lazy 'LB.ByteString'
data GetObject = GetObject { bucket :: Bucket, object :: Object }
    deriving ( Show, Eq, Generic )

data GetObjectResponse = GetObjectResponse
    { objectMetadata :: ObjectMetadata, objectData :: LB.ByteString }
    deriving ( Show, Eq, Generic )

instance MonadSpaces m => Action m GetObject where
    type (SpacesResponse GetObject) = GetObjectResponse

    buildRequest GetObject { .. } = do
        spaces <- ask
        return SpacesRequestBuilder
               { bucket         = Just bucket
               , object         = Just object
               , method         = Nothing
               , body           = Nothing
               , queryString    = Nothing
               , overrideRegion = Nothing
               , headers        = mempty
               , ..
               }

    consumeResponse raw@RawResponse { .. } = GetObjectResponse
        <$> getObjectMetadata raw
        <*> runConduit (body .| sinkLbs)