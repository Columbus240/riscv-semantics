{-# LANGUAGE ScopedTypeVariables #-}
module ExecuteM where
import Decode
import Program
import Utility
import Control.Monad

execute :: forall p t u. (RiscvProgram p t u) => Instruction -> p ()
execute (Mul rd rs1 rs2) = do
  x <- getRegister rs1
  y <- getRegister rs2
  setRegister rd (x * y)
execute (Mulh rd rs1 rs2) = do
  x <- getRegister rs1
  y <- getRegister rs2
  setRegister rd (highBits ((fromIntegral x) * (fromIntegral y))::t)
execute (Mulhsu rd rs1 rs2) = do
  x <- getRegister rs1
  y <- getRegister rs2
  setRegister rd (highBits ((fromIntegral x) * (fromIntegral $ unsigned y))::t)
execute (Mulhu rd rs1 rs2) = do
  x <- getRegister rs1
  y <- getRegister rs2
  setRegister rd (highBits ((fromIntegral $ unsigned x) * (fromIntegral $ unsigned y))::t)
execute (Div rd rs1 rs2) = do
  x <- getRegister rs1
  y <- getRegister rs2
  let q | x == minBound && y == -1 = x
        | y == 0 = -1
        | otherwise = x `div` y
    in setRegister rd q
execute (Divu rd rs1 rs2) = do
  x <- getRegister rs1
  y <- getRegister rs2
  let q | y == 0 = maxBound::u
        | otherwise = (unsigned x) `div` (unsigned y)
    in setRegister rd q
execute (Rem rd rs1 rs2) = do
  x <- getRegister rs1
  y <- getRegister rs2
  let r | x == minBound && y == -1 = 0
        | y == 0 = x
        | otherwise = x `rem` y
    in setRegister rd r
execute (Remu rd rs1 rs2) = do
  x <- getRegister rs1
  y <- getRegister rs2
  let r | y == 0 = x
        | otherwise = fromIntegral $ (unsigned x) `rem` (unsigned y)
    in setRegister rd r
execute _ = mzero
