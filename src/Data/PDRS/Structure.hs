{- |
Module      :  Data.PDRS.Structure
Copyright   :  (c) Harm Brouwer and Noortje Venhuizen
License     :  Apache-2.0

Maintainer  :  me@hbrouwer.eu, n.j.venhuizen@rug.nl
Stability   :  provisional
Portability :  portable

PDRS data structure
-}

module Data.PDRS.Structure
(
-- * PDRS data type
  PDRS (..)
, DRSVar
, PVar
, MAP
, PRef (..)
, PDRSRef (..)
, PDRSRel (..)
, PCon (..)
, PDRSCon (..)
, DRSRel
-- * Basic functions on PDRSs
, isLambdaPDRS
, pdrsLabel
, pdrsUniverse
, isSubPDRS
) where

import Data.DRS.Structure (DRSRel, DRSVar)

---------------------------------------------------------------------------
-- * Exported
---------------------------------------------------------------------------

---------------------------------------------------------------------------
-- ** PDRS data type
---------------------------------------------------------------------------

---------------------------------------------------------------------------
-- | Projective Discourse Representation Structure.
---------------------------------------------------------------------------
data PDRS =
  LambdaPDRS ((DRSVar,[DRSVar]),Int)
  -- ^ A lambda 'PDRS' (a variable, the set of referents
  -- to be applied to the PDRS, and its argument position)
  | AMerge PDRS PDRS
  -- ^ An assertive merge between two 'PDRS's
  | PMerge PDRS PDRS
  -- ^ A projective merge between two 'PDRS's
  | PDRS PVar [MAP] [PRef] [PCon]
  -- ^ A 'PDRS', consisting of a 'PVar' (a label), 
  -- a set of 'MAP's, a set of 'PRef's, and a set of 'PCon's
  deriving (Eq)

---------------------------------------------------------------------------
-- | Projection variable (a label or pointer).
---------------------------------------------------------------------------
type PVar = Int

---------------------------------------------------------------------------
-- | Minimally Accessible 'PDRS', represented as a tuple between a 'PVar'
-- and another 'PVar' that is /minimally accessible/ from the first 'PVar'.
---------------------------------------------------------------------------
type MAP = (PVar,PVar)

---------------------------------------------------------------------------
-- | A projected referent, consisting of a 'PVar' and a 'PDRSRef'.
---------------------------------------------------------------------------
data PRef = PRef PVar PDRSRef
  deriving (Eq,Show)

---------------------------------------------------------------------------
-- | A 'PDRS' referent.
---------------------------------------------------------------------------
data PDRSRef =
  LambdaPDRSRef ((DRSVar,[DRSVar]),Int)
  -- ^ A lambda PDRS referent (a variable, the set of referents
  -- to be applied to the referent, and its argument position)
  | PDRSRef DRSVar
  -- ^ A PDRS referent
  deriving (Eq,Show)

---------------------------------------------------------------------------
-- | PDRS relation
---------------------------------------------------------------------------
data PDRSRel =
  LambdaPDRSRel ((DRSVar,[DRSVar]),Int)
  | PDRSRel String
  deriving (Eq)

---------------------------------------------------------------------------
-- | A projected condition, consisting of a 'PVar' and a 'PDRSCon'.
---------------------------------------------------------------------------
data PCon = PCon PVar PDRSCon
  deriving (Eq)

---------------------------------------------------------------------------
-- | A 'PDRS' condition.
---------------------------------------------------------------------------
data PDRSCon = 
  Rel PDRSRel [PDRSRef] -- ^ A relation defined on a set of referents
  | Neg PDRS            -- ^ A negated 'PDRS'
  | Imp PDRS PDRS       -- ^ An implication between two 'PDRS's
  | Or PDRS PDRS        -- ^ A disjunction between two 'PDRS's
  | Prop PDRSRef PDRS   -- ^ A proposition 'PDRS'
  | Diamond PDRS        -- ^ A possible 'PDRS'
  | Box PDRS            -- ^ A necessary 'PDRS'
  deriving (Eq)

---------------------------------------------------------------------------
-- ** Basic functions on PDRSs
---------------------------------------------------------------------------

---------------------------------------------------------------------------
-- | Returns whether a PDRS is entirely a 'LambdaPDRS' (at its top-level)
---------------------------------------------------------------------------
isLambdaPDRS :: PDRS -> Bool
isLambdaPDRS (LambdaPDRS {}) = True
isLambdaPDRS (AMerge p1 p2)  = isLambdaPDRS p1 && isLambdaPDRS p2
isLambdaPDRS (PMerge p1 p2)  = isLambdaPDRS p1 && isLambdaPDRS p2
isLambdaPDRS (PDRS {})       = False

---------------------------------------------------------------------------
-- | Returns the label of a 'PDRS'.
---------------------------------------------------------------------------
pdrsLabel :: PDRS -> PVar
pdrsLabel (LambdaPDRS _) = 0
pdrsLabel (AMerge p1 p2)
  | isLambdaPDRS p2 = pdrsLabel p1
  | otherwise       = pdrsLabel p2
pdrsLabel (PMerge p1 p2)
  | isLambdaPDRS p2 = pdrsLabel p1
  | otherwise       = pdrsLabel p2
pdrsLabel (PDRS l _ _ _) = l

---------------------------------------------------------------------------
-- | Returns the universe of a PDRS
---------------------------------------------------------------------------
pdrsUniverse :: PDRS -> [PRef]
pdrsUniverse (LambdaPDRS _)  = []
pdrsUniverse (AMerge p1 p2) = pdrsUniverse p1 ++ pdrsUniverse p2
pdrsUniverse (PMerge p1 p2) = pdrsUniverse p1 ++ pdrsUniverse p2
pdrsUniverse (PDRS _ _ u _) = u

---------------------------------------------------------------------------
-- | Returns whether 'PDRS' @p1@ is a direct or indirect sub-'PDRS' of
-- 'PDRS' @p2@.
---------------------------------------------------------------------------
isSubPDRS :: PDRS -> PDRS -> Bool
isSubPDRS p1 (LambdaPDRS _)    = False
isSubPDRS p1 (AMerge p2 p3)    = isSubPDRS p1 p2 || isSubPDRS p1 p3
isSubPDRS p1 (PMerge p2 p3)    = isSubPDRS p1 p2 || isSubPDRS p1 p3
isSubPDRS p1 p2@(PDRS _ _ _ c) = p1 == p2 || any subPDRS c
  where subPDRS :: PCon -> Bool
        subPDRS (PCon _ (Rel _ _ ))   = False
        subPDRS (PCon _ (Neg p3))     = isSubPDRS p1 p3
        subPDRS (PCon _ (Imp p3 p4))  = isSubPDRS p1 p3 || isSubPDRS p1 p4
        subPDRS (PCon _ (Or p3 p4))   = isSubPDRS p1 p3 || isSubPDRS p1 p4
        subPDRS (PCon _ (Prop _ p3))  = isSubPDRS p1 p3
        subPDRS (PCon _ (Diamond p3)) = isSubPDRS p1 p3
        subPDRS (PCon _ (Box p3))     = isSubPDRS p1 p3

