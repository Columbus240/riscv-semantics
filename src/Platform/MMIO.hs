{-# LANGUAGE MultiParamTypeClasses, FlexibleInstances, FlexibleContexts, MultiWayIf, UndecidableInstances, ScopedTypeVariables, InstanceSigs #-}
module Platform.MMIO where
import Data.Bits
import Data.Int
import Data.Char
import Control.Monad.Identity
import Control.Monad.State
import System.IO.Error
import qualified Data.Map as S

import Spec.Machine
import Utility.Utility

type IOState s = StateT s IO

type LoadFunc s = IOState s Int32
type StoreFunc s = Int32 -> IOState s ()

instance (Show (LoadFunc s)) where
  show _ = "<io/loadfunc>"
instance (Show (StoreFunc s)) where
  show _ = "<io/storefunc>"

cGetChar :: IO Int32
cGetChar = catchIOError (fmap ((fromIntegral:: Int -> Int32). ord) getChar) (\e -> if isEOFError e then return (-1) else ioError e)

rvGetChar :: LoadFunc s
rvGetChar = liftIO cGetChar
rvPutChar :: StoreFunc s
rvPutChar val = liftIO (putChar $ chr $ (fromIntegral:: Int32 -> Int) val)

rvZero :: LoadFunc s
rvZero = return 0
rvNull :: StoreFunc s
rvNull val = return ()

-- Addresses for mtime/mtimecmp chosen for Spike compatibility.
mmioTable :: S.Map MachineInt (LoadFunc s, StoreFunc s)
mmioTable = S.fromList [(0xfff0, (rvZero, rvPutChar)), (0xfff4, (rvGetChar, rvNull))]

instance (RiscvMachine (State s) t, MachineWidth t) => RiscvMachine (IOState s) t where
  getRegister r = liftState (getRegister r)
  setRegister r v = liftState (setRegister r v)
  getFPRegister r = liftState (getFPRegister r)
  setFPRegister r v = liftState (setFPRegister r v)
  loadByte a = liftState (loadByte a)
  loadHalf a = liftState (loadHalf a)
  loadWord :: t -> IOState s Int32
  loadWord addr =
    case S.lookup ((fromIntegral:: t -> MachineInt) addr) mmioTable of
      Just (getFunc, _) -> getFunc
      Nothing -> liftState (loadWord addr)
  loadDouble a = liftState (loadDouble a)
  storeByte a v = liftState (storeByte a v)
  storeHalf a v = liftState (storeHalf a v)
  storeWord :: t -> Int32 -> IOState s ()
  storeWord addr val =
    case S.lookup ((fromIntegral:: t -> MachineInt) addr) mmioTable of
      Just (_, setFunc) -> setFunc val
      Nothing -> liftState (storeWord addr val)
  storeDouble a v = liftState (storeDouble a v)
  makeReservation a = liftState (makeReservation a)
  checkReservation a = liftState (checkReservation a)
  clearReservation a = liftState (clearReservation a)
  getCSRField f = liftState (getCSRField f)
  unsafeSetCSRField f v = liftState (setCSRField f v)
  getPC = liftState getPC
  setPC v = liftState (setPC v)
  getPrivMode = liftState getPrivMode
  setPrivMode v = liftState (setPrivMode v)
  commit = liftState commit
  endCycle = liftState endCycle
  inTLB a b = liftState (inTLB a b)-- noTLB
  addTLB a b c= liftState (addTLB a b c) 
  flushTLB = liftState flushTLB
  getPlatform = liftState getPlatform
