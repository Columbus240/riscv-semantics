import ParseToJson hiding (main)
import Debug.Trace (trace)
import Control.Monad
import Data.List
import System.IO.Unsafe

coqPrint (If cond ifT ifF) =
  let lineif = join . (intersperse " ")  $ ["if", coqPrint cond]
      linethen = join . (intersperse " ")  $ [ "then", coqPrint ifT]
      lineelse = join . (intersperse " ")  $ [ "else", coqPrint ifF] in
    (\l-> "(" ++ l ++ ")") . join . (intersperse "\n ")  $ [lineif ,linethen ,lineelse]
coqPrint (Arith TokenMPLUS l) =
   (\l-> "(" ++ l ++ ")") . join . intersperse " ^+ " $ fmap coqPrint l
coqPrint (Arith TokenMTIMES l) =
   (\l-> "(" ++ l ++ ")") . join . intersperse " * " $ fmap coqPrint l
coqPrint (Arith TokenMMINUS [a]) = "(-" ++ coqPrint a ++")" -- TODO check
coqPrint (Arith TokenMMINUS l) =
   (\l-> "(" ++ l ++ ")") . join . intersperse " ^- " $ fmap coqPrint l
coqPrint (Arith TokenMOR l) =
   (\l-> "(wor " ++ l ++ ")") . join . intersperse " " $ fmap coqPrint l
coqPrint (Arith TokenMAND l) =
   (\l-> "(wand " ++ l ++ ")") . join . intersperse " " $ fmap coqPrint l
coqPrint (Arith TokenMBAND l) = -- Gallina boolean and
   (\l-> "(" ++ l ++ ")") . join . intersperse " and " $ fmap coqPrint l
coqPrint (Arith TokenMBOR l) = -- Gallina boolean or
   (\l-> "(" ++ l ++ ")") . join . intersperse " or " $ fmap coqPrint l
coqPrint (Arith TokenMTYPEOF l) = -- Just ignore that
  coqPrint $ head l -- (\l-> "(" ++ l ++ ")") . join . intersperse " : " $ fmap coqPrint l
coqPrint (Arith TokenMEQUAL l) =
   (\l-> "(weq " ++ l ++ ")") . join . intersperse " " $ fmap coqPrint l
coqPrint (Arith TokenMDIFF l) =
   (\l-> "(wneq " ++ l ++ ")") . join . intersperse " " $ fmap coqPrint l
coqPrint (Arith TokenMLT l) =
   (\l-> "(wlt_dec " ++ l ++ ")") . join . intersperse " " $ fmap coqPrint l
coqPrint (Arith TokenMGT l) =
   (\l-> "(wgt_dec" ++ l ++ ")") . join . intersperse " " $ fmap coqPrint l
coqPrint (Arith TokenMLEQ l) =
   (\l-> "(wleq_dec " ++ l ++ ")") . join . intersperse " " $ fmap coqPrint l
coqPrint (Arith TokenMGEQ l) =
   (\l-> "(wgeq_dec " ++ l ++ ")") . join . intersperse " " $ fmap coqPrint l

coqPrint (App a b) =
    join . intersperse " " $ ["(", coqPrint a , coqPrint b, ")"]
coqPrint (Num a) = "$" ++ show a
coqPrint  (Iden s)
  | s == "imm20" = "(upper_imm_to_word imm20)"
  | s == "jimm20" = "(signed_jimm_to_word jimm20)"
  | s == "oimm12" = "(upper_imm_to_word oimm12)" -- Not used by Sam (Load)
  | s == "sbimm12" = "(signed_bimm_to_word sbimm12)"
  | s == "simm12" = "(upper_imm_to_word simm12)" -- Not used by Sam (Store)
  | s == "imm12" = "(signed_imm_to_word imm12)"
  | s == "shamt6" = "(wordToNat shamt6)"
  | s == "unsigned" = ""
  | s == "noAction" = "(Return tt)"
  | s == "mod" = "modulo"
  | s == "xor" = "wxor"
  | s == "shiftL" = "wlshift"
  | s == "shiftR" = "wrshift"
  | s == "shiftBits" = ""
  | s == "fromIntegral" = ""
  | otherwise = s

coqPrint (Do ((Bind name b):q)) =
  let firstline = join . intersperse " " $ [name, "<-", coqPrint b ++ ";"] in
    join . intersperse "\n" $ [ firstline, coqPrint (Do q)]
coqPrint (Do ([t])) = join . intersperse " " $ [ coqPrint t]
coqPrint (Do (t:q)) = join . intersperse "\n" $ [ coqPrint t++";;",  coqPrint (Do q)]
coqPrint (Do []) = ""
coqPrint (Let s l body) =
  let firstline = join . intersperse " " $ ["let", s, ":=", nestedIf l, "in"] in 
      join . intersperse "\n" $ [firstline, coqPrint body]
coqPrint x = trace (show x) undefined


printMatcher (App a b) = join . intersperse " " $ [printMatcher a, printMatcher b]
printMatcher (Iden s) = s

executeCoq ((ExecuteCase a b):q) =
  let firstline = join . intersperse " " $ ["|", printMatcher a, "=>"]in
    join . intersperse "\n" $ [firstline , coqPrint b, executeCoq q]
executeCoq [] = ""

nestedIf [(Iden "otherwise",t)] = coqPrint t
nestedIf ((c,t):q) = join .intersperse " " $ ["(","if", coqPrint c, "then\n", coqPrint t, "else\n", nestedIf q, ")"]


transliterateCoq l ="Definition execute{M: Type -> Type}{MM: Monad M}{RVS: RiscvState M}(i: Instruction): M unit :=\nmatch i with\n" ++ executeCoq l ++ "\nend."

main = putStrLn . transliterateCoq .  riscv . lexer . drop 13 .  stopWhen (isPrefixOf "-- end ast") . dropUntil (isPrefixOf "-- begin ast") . unsafePerformIO $ readFile "ExecuteI.hs"

-- main =  readFile "ExecuteI.hs" >>= print. riscv. lexer. drop 13 .  stopWhen (isPrefixOf "-- end ast") . dropUntil (isPrefixOf "-- begin ast")
