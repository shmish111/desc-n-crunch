module Descriptions.Traversable

import Descriptions.Core
%default total
%access export
%auto_implicits off

using (g: Type -> Type)
  zipA : Applicative g => {a, b: _} -> g a -> g b -> g (x : a ** b)
  zipA {a} {b} x y = zipD <$> x <*> y
    where zipD : a -> b -> (x : a ** b)
          zipD x y = (x ** y)

  mutual
    gtraversed : Applicative g => {a,b,Ix: _} -> (dr: PDesc (S Z) Ix) -> (PConstraints1 Traversable dr)
                                              -> (d: PDesc (S Z) Ix) -> (PConstraints1 Traversable d) -> {ix : Ix}
                                              -> (k : g (PSynthesize d b (PData dr b) ix) -> g (PData dr b ix))
                                              -> (a -> g b) -> PSynthesize d a (PData dr a) ix -> g (PData dr b ix)
    gtraversed dr constraintsr (PRet ix) constraints k f Refl = k (pure Refl)
    gtraversed dr constraintsr (PArg A kdesc) constraints k f (arg ** rest) =
     gtraversed dr constraintsr (kdesc arg) (constraints arg) (\idm => k (MkDPair arg <$> idm)) f rest
    gtraversed dr constraintsr (PPar FZ kdesc) constraints k f (par ** rest) =
     gtraversed dr constraintsr kdesc constraints (\idm => k (zipA (f par) idm)) f rest
    gtraversed _ _ (PPar (FS FZ) _) _ _ _ _ impossible
    gtraversed _ _ (PPar (FS (FS _)) _) _ _ _ _ impossible
    gtraversed dr constraintsr (PMap g FZ kdesc) (trav, constraints) k f (targ ** rest) =
      gtraversed dr constraintsr kdesc constraints (\idm => k (zipA (traverse @{trav} f targ) idm)) f rest
    gtraversed _ _ (PMap _ (FS FZ) _) _ _ _ _ impossible
    gtraversed _ _ (PMap _ (FS (FS _)) _) _ _ _ _ impossible
    gtraversed dr constraintsr (PRec ix kdesc) constraints k f (rec ** rest) =
      gtraversed dr constraintsr kdesc constraints (\idm => k (zipA (gtraverse dr constraintsr f rec) idm)) f rest
    gtraverse  : Applicative g => {a,b,Ix: _} -> (d: PDesc (S Z) Ix) -> (PConstraints1 Traversable d) -> {ix : Ix}
                                              -> (a -> g b) -> PData d a ix -> g (PData d b ix)
    gtraverse d constraints f (Con x) = assert_total $ gtraversed d constraints d constraints (Con <$>) f x
