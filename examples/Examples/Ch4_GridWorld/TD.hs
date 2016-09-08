module Examples.Ch4_GridWorld.TD where

import qualified Data.HashMap.Strict as HashMap
import qualified Data.Set as Set
import qualified Data.Map as Map
import qualified Prelude

import RL.Types hiding (Q, q2v)
import RL.Imports
import RL.TD.Types as TD
import RL.TD as TD

import Examples.Ch4_GridWorld.Base(GW(..), Point, Action)
import qualified Examples.Ch4_GridWorld.Base as GW
import qualified Examples.Ch4_GridWorld.DP as DP

data TD_GW m = TD_GW {
    gw :: GW TD_Number
  , gw_trace :: Point -> Action -> Q Point Action -> m ()
  }

instance (Monad m) => TD_Problem (TD_GW m) m Point Action where
  td_is_terminal TD_GW{..} p = GW.isTerminal gw p
  td_greedy TD_GW{..} best = id
  td_reward TD_GW{..} s a s' = -1
  td_transition TD_GW{..} s a q = do
    gw_trace s a q
    return (GW.transition gw s a)

sv2v :: (Hashable s, Eq s) => StateVal TD_Number s -> V s
sv2v sv = HashMap.fromList $ Map.toList $ v_map sv

showV gw v = GW.showGW gw (\p -> HashMap.lookup p v)

gw_iter_q :: GW TD_Number -> IO ()
gw_iter_q gw =
  let
    -- Q options
    o = Q_Opts {
           o_alpha = 0.1
         , o_gamma = 1.0
         , o_eps = 0.7
         }

    q0 = TD.emptyQ 0   -- Initial Q table
    g0 = pureMT 33     -- Initial RNG
    cnt = 20*10^3

    st_q :: Lens' (a,b) a
    st_q = _1
    st_i :: Lens' (a,b) b
    st_i = _2
  in do

  {- Reference StateVal -}
  v_dp <- DP.gw_iter_dp gw

  GW.withLearnPlot cnt $ \d -> do
    flip evalRndT_ g0 $ do
      flip execStateT (q0,0) $ do
        loop $ do
          s0 <- GW.arbitraryState gw
          q <- use st_q

          qlearn o q s0 $ TD_GW gw $ \s a q -> do
            liftIO $ putStrLn $ show s <> "  " <> GW.showAction a
            i <- use st_i
            when (i >= cnt) $ do
              liftIO $ putStrLn $ "Exiting at " <> show i
              break ()
            st_q %= const q
            st_i %= (+1)

          (q',i) <- get
          liftIO $ putStrLn $ "Loop i = " <> show i
          liftIO $ showV gw (q2v q')
          liftIO $ pushData d i (diffV (q2v q') (sv2v v_dp))
          st_q %= const q'

