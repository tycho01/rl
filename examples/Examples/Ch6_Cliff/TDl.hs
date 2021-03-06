module Examples.Ch6_Cliff.TDl (
    cw_iter_tdl
  , cw_iter_qlw
  ) where

import qualified Prelude
import qualified Data.HashMap.Strict as HashMap

import RL.Imports
import RL.TDl as TDl

import Examples.Ch6_Cliff.Rules(CW(..), Point, Action)
import qualified Examples.Ch6_Cliff.Rules as Rules

data TD_CW m = TD_CW {
    cw :: CW
  , cw_trace :: Point -> Action -> Q Point Action -> m ()
  }

instance (Monad m) => TDl_Problem (TD_CW m) m Point Action where
  td_is_terminal TD_CW{..} p = (p == Rules.exits cw)
  td_greedy TD_CW{..} best = id
  td_reward TD_CW{..} = Rules.reward cw
  td_transition TD_CW{..} s a st = return (fst $ Rules.transition cw s a)
  td_modify TD_CW{..} s a st = cw_trace s a (st^.tdl_q)

showV gw v = Rules.showV gw (HashMap.toList v)

cw_iter_tdl :: CW -> IO ()
cw_iter_tdl cw =
  let
    o = TDl_Opts {
           o_alpha = 0.1
         , o_gamma = 1.0
         , o_eps = 0.7
         , o_lambda = 0.8
         }

    q0 = TDl.emptyQ 0   -- Initial Q table
    g0 = pureMT 33     -- Initial RNG
    cnt = 20*10^3 :: Integer

    st_q :: Lens' (a,b) a
    st_q = _1
    st_i :: Lens' (a,b) b
    st_i = _2
  in do

  flip evalRndT_ g0 $ do
    flip execStateT (q0,0) $ do
      loop $ do
        s0 <- Rules.pickState cw
        i <- use st_i
        q <- use st_q

        (s',q') <-
          tdl_learn o q s0 $ TD_CW cw $ \s a q -> do
            i <- use st_i
            when (i >= cnt) $ do
              break ()

        liftIO $ putStrLn $ "Loop i = " <> show i
        liftIO $ showV cw (TDl.toV q')
        st_i %= const (i+1)
        st_q %= const q'


cw_iter_qlw :: CW -> IO ()
cw_iter_qlw cw =
  let
    o = TDl_Opts {
           o_alpha = 0.1
         , o_gamma = 1.0
         , o_eps = 0.7
         , o_lambda = 0.8
         }

    q0 = TDl.emptyQ 0   -- Initial Q table
    g0 = pureMT 33     -- Initial RNG
    cnt = 20*10^3 :: Integer

    st_q :: Lens' (a,b) a
    st_q = _1
    st_i :: Lens' (a,b) b
    st_i = _2
  in do

  flip evalRndT_ g0 $ do
    flip execStateT (q0,0) $ do
      loop $ do
        s0 <- Rules.pickState cw
        i <- use st_i
        q <- use st_q

        (s',q') <-
          qlw_learn o q s0 $ TD_CW cw $ \s a q -> do
            i <- use st_i
            when (i >= cnt) $ do
              break ()

        liftIO $ putStrLn $ "Loop i = " <> show i
        liftIO $ showV cw (TDl.toV q')
        st_i %= const (i+1)
        st_q %= const q'

