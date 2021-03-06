{-|
  Satton, 'Reinforcement Learning: The Introduction', pg.86, Example 4.1: GridWorld
-}

{-# LANGUAGE DeriveAnyClass #-}
{-# LANGUAGE DeriveGeneric #-}
module Examples.Ch4_GridWorld.Rules where

import qualified Data.List as List
import qualified Data.Map.Strict as Map
import qualified Data.Set as Set

import RL.Types
import RL.Imports
import RL.DP

type Point = (Int,Int)

data Action = L | R | U | D
  deriving(Show, Eq, Ord, Enum, Bounded, Generic, Hashable)

data GW num = GW {
    gw_size :: (Int,Int),
    gw_exits :: Set (Int,Int)
  } deriving(Show)

showAction :: Action -> String
showAction a =
  case a of
    L->"<"
    R->">"
    U->"^"
    D->"v"

showActions :: Set Action -> String
showActions = concat . map showAction . List.sort . Set.toList

states ::  GW num -> Set Point
states (GW (sx,sy) _) = Set.fromList [(x,y) | x <- [0..sx-1], y <- [0..sy-1]]

actions :: GW num -> Point -> Set Action
actions (GW (sx,sy) exits) s =
    case Set.member s exits of
      True -> Set.empty
      False -> Set.fromList [minBound..maxBound]

transition :: GW num -> Point -> Action -> Point
transition (GW (sx,sy) exits) (x,y) a =
  let
    check (x',y') =
      if x' >= 0 && x' < sx && y' >= 0 && y' < sy then
        (x',y')
      else
        (x,y)
  in
  case a of
    L -> check (x-1,y)
    R -> check (x+1,y)
    U -> check (x,y-1)
    D -> check (x,y+1)

showV :: (MonadIO m, Real num) => GW num -> [(Point, num)] -> m ()
showV (GW (sx,sy) _) v = liftIO $ do
  forM_ [0..sy-1] $ \y -> do
    forM_ [0..sx-1] $ \x -> do
      case List.lookup (x,y) v of
        Just v -> do
          printf "%-2.3f " ((fromRational $ toRational v) :: Double)
        Nothing -> do
          printf "  ?   "
    printf "\n"

-- TODO: remove recursion
arbitraryState :: MonadRnd g m => GW t -> m Point
arbitraryState gw@GW{..} = do
    let (sx,sy) = gw_size
    x <- getRndR (0,sx-1)
    y <- getRndR (0,sy-1)
    case isTerminal gw (x,y) of
      True -> arbitraryState gw
      False -> return (x,y)


isTerminal :: GW num -> Point -> Bool
isTerminal GW{..} p = p `Set.member` gw_exits

withLearnPlot :: Show a => a -> (PlotData -> IO b) -> IO b
withLearnPlot cnt f = do
  d <- newData "learnRate"
  withPlot "plot1" [heredoc|
    set grid back ls 102
    set xrange [0:${show cnt}]
    set yrange [-20:20]
    set terminal x11 1 noraise
    done = 0
    bind all 'd' 'done = 1'
    while(!done) {
      plot ${dat d} using 1:2 with lines
      pause 1
    }
    |] (f d)

