{-# LANGUAGE DataKinds         #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TemplateHaskell   #-}

-- Module      : Network.PagerDuty.Alerts
-- Copyright   : (c) 2013-2014 Brendan Hay <brendan.g.hay@gmail.com>
-- License     : This Source Code Form is subject to the terms of
--               the Mozilla Public License, v. 2.0.
--               A copy of the MPL can be found in the LICENSE file or
--               you can obtain it at http://mozilla.org/MPL/2.0/.
-- Maintainer  : Brendan Hay <brendan.g.hay@gmail.com>
-- Stability   : experimental
-- Portability : non-portable (GHC extensions)

-- | When an incident is triggered or when it is escalated it creates an alert
-- (also known as a notification). Alerts are messages containing the details
-- of the incident, and can be sent through SMS, email, phone calls,
-- and push notifications.
--
-- This API allows you to access read-only data regarding what alerts have been
-- sent to your users.
--
-- See: <http://developer.pagerduty.com/documentation/rest/alerts>
module Network.PagerDuty.Alerts
    (
    -- * Operations
    -- ** List
      listAlerts
    , laSince
    , laUntil
    , laFilter
    , laTimeZone

    -- * Types
    , AlertType (..)

    , Alert
    , alertId
    , alertType
    , alertStartedAt
    , alertUser
    , alertAddress
    ) where

import           Control.Lens            hiding ((.=))
import           Data.Aeson              (ToJSON)
import           Data.Aeson.Lens
import qualified Data.ByteString         as BS
import           Network.HTTP.Types
import           Network.PagerDuty.TH
import           Network.PagerDuty.Types

req :: ToJSON a => StdMethod -> Unwrap -> a -> Request a s r
req m u = req' m ("alerts", BS.empty) u

data AlertType
    = SMS
    | Email
    | Phone
    | Push
      deriving (Eq, Show)

deriveJSON ''AlertType

data Alert = Alert
    { _alertId        :: AlertId
    , _alertType      :: AlertType
    , _alertStartedAt :: Date
    , _alertUser      :: User
    , _alertAddress   :: Address
    } deriving (Eq, Show)

deriveJSON ''Alert
makeLenses ''Alert

data ListAlerts = ListAlerts
    { _laSince    :: Date
    , _laUntil    :: Date
    , _laFilter   :: Maybe AlertType
    , _laTimeZone :: Maybe TimeZone
    } deriving (Eq, Show)

-- | List existing alerts for a given time range, optionally filtered by type
-- (SMS, Email, Phone, or Push).
--
-- @GET \/alerts@
--
-- See: <http://developer.pagerduty.com/documentation/rest/alerts/list>
listAlerts :: Date -- ^ 'laSince'
           -> Date -- ^ 'laUntil'
           -> Request ListAlerts Token [Alert]
listAlerts s u = req GET (key "alerts") $
    ListAlerts
        { _laSince    = s
        , _laUntil    = u
        , _laFilter   = Nothing
        , _laTimeZone = Nothing
        }

-- | The start of the date range over which you want to search.
makeLens "_laSince" ''ListAlerts

-- | The end of the date range over which you want to search.
-- This should be in the same format as 'since'.
--
-- The size of the date range must be less than 3 months.
makeLens "_laUntil" ''ListAlerts

-- | Returns only the alerts of the said 'AlertType' type.
makeLens "_laFilter" ''ListAlerts

-- | Time zone in which dates in the result will be rendered.
--
-- Defaults to account time zone.
makeLens "_laTimeZone" ''ListAlerts

deriveJSON ''ListAlerts

instance Paginate ListAlerts
