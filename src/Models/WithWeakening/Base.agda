{-# OPTIONS --allow-unsolved-metas  --lossy-unification #-}

open import Cubical.Foundations.Prelude
open import Cubical.Foundations.HLevels hiding (extend)
open import Cubical.Functions.Embedding

open import Cubical.Categories.Bifunctor.Redundant
open import Cubical.Categories.Category
open import Cubical.Categories.Functor
open import Cubical.Categories.Instances.Functors
open import Cubical.Categories.Instances.Sets 
open import Cubical.Categories.Monad.Base
open import Cubical.Categories.NaturalTransformation

open import Cubical.Data.Bool 
open import Cubical.Data.FinSet
open import Cubical.Data.FinSet.Constructors
open import Cubical.Data.FinSet.DecidablePredicate 
open import Cubical.Data.Nat
open import Cubical.Data.Sigma
open import Cubical.Data.Sum
open import Cubical.Data.Unit

open import Cubical.HITs.SetQuotients renaming ([_] to q[_]) hiding (rec)

open Category
open Functor

module src.Models.WithWeakening.Base {ℓS : Level} where


    -- Syntactic Types
    module SyntacticTypes  where 

        data SynTy' : Type ℓS where 
            u n b : SynTy'

        SynTyisSet : isSet SynTy' 
        SynTyisSet = {!  !}

        SynTy : hSet ℓS 
        SynTy = SynTy' , SynTyisSet
    
    module Worlds where 
        open SyntacticTypes
        open import src.Data.FinSet
        open import Cubical.Categories.Displayed.Constructions.Comma
        open import Cubical.Categories.Instances.Terminal


        Inc : Functor (FinSetMono{ℓS}) (SET ℓS)
        Inc .F-ob (ty , fin) = ty , isFinSet→isSet fin 
        Inc .F-hom (f , _) x = f x
        Inc .F-id = refl
        Inc .F-seq (f , _) (g , _) = refl
        
        G : Functor (TerminalCategory {ℓS}) ((SET ℓS))
        G = FunctorFromTerminal SynTy

        -- this variance is used for the semicartisian day conv
        -- this is essentially a slice category but the Identity functor is replaced with an inclusion functor
        -- so that we have the top maps of the slice homs as injective functions
        W : Category (ℓ-suc ℓS) ℓS
        W = (Comma Inc G) ^op

        _ : isSet (Σ[ X ∈ FinSet ℓS ] Unit* → SynTy')
        _ = isSet→ {A' = SynTy'}{A = Σ[ X ∈ FinSet ℓS ] Unit* } SynTyisSet   
        wset : isSet (ob W)
        wset = isSetΣ (isSetΣ {! isFinSet→isSet !} λ _ → isSetUnit*) λ _ → {!  !}

    module CBPV
            {ℓS ℓC ℓC' : Level}
            (W : Category ℓC ℓC')
            (isSetWob : isSet (ob W)) where 
            
        open import Cubical.Categories.Adjoint
        open import Cubical.Categories.Adjoint.Monad
        open import Cubical.Categories.Instances.Discrete
        open import Cubical.Categories.Presheaf.Base
        open import Cubical.Categories.Presheaf.Constructions

        ℓ = (ℓ-max (ℓ-max ℓC ℓC') ℓS)

        |W| : Category ℓC ℓC 
        |W| = (DiscreteCategory (ob W , isSet→isGroupoid isSetWob))

        Inc : Functor |W| W
        Inc = DiscFunc λ x → x

        Inc^op : Functor |W| (W ^op)
        Inc^op = DiscFunc λ x → x
        
        -- since World is already ^op
        -- this is morally a covariant presheaf category
        -- op ^ op ↦ id
        𝒱 : Category (ℓ-suc ℓ) ℓ
        𝒱 = PresheafCategory W ℓ

        -- since World is already ^op
        -- this is morally a contravariant (normal) presheaf category
        -- op ^ op ^ op ↦ op
        𝒞 : Category (ℓ-suc ℓ) ℓ
        𝒞 = PresheafCategory (W ^op) ℓ

        _×P_ : ob 𝒱 → ob 𝒱 → ob 𝒱
        (P ×P Q)  = PshProd ⟅ P , Q ⟆b

        Fam : Category (ℓ-suc ℓ) ℓ
        Fam = FUNCTOR |W| (SET ℓ)

        open import src.Data.Direct
        module Future = Lan {ℓS = ℓ} (W ^op) isSetWob
        module Past = Ran {ℓS = ℓ} W isSetWob
        open UnitCounit
        
        Inc* : Functor 𝒞 Fam 
        Inc* = precomposeF (SET ℓ) (Inc)

        Inc^op* : Functor 𝒱 Fam 
        Inc^op* = precomposeF (SET ℓ) (Inc^op)
        
        F' : Functor Fam 𝒞 
        F' = Future.Lan

        F : Functor 𝒱 𝒞 
        F = F' ∘F Inc^op*

        adjF : F' ⊣ Inc*
        adjF = Future.adj

        U' : Functor Fam 𝒱 
        U' = Past.Ran

        U : Functor 𝒞 𝒱 
        U = U' ∘F Inc*

        adjU : Inc^op* ⊣ U' 
        adjU = Past.adj

    module Monoids where 
        open Worlds 
        open CBPV {ℓS} W wset


        open import Cubical.Categories.Constructions.BinProduct 
        open import Cubical.Categories.Monoidal.Base
        
        open import Cubical.Data.Empty hiding (rec)
        open import Cubical.Data.SumFin.Base 

        open import Cubical.HITs.PropositionalTruncation hiding(rec ; map)

        -- Monoid on Worlds
        
        emptyFin* : isFinSet {ℓS} (Lift ⊥)
        emptyFin* = 0 , ∣ (λ()) , record { equiv-proof = λ() } ∣₁

        emptymap : ob W 
        emptymap = ((Lift (Fin 0 ) , emptyFin*) , tt*) , λ() 

        _⨂_ : Functor (W ×C W) W
        _⨂_ .F-ob ((((X , Xfin) , tt* ) , w) , (((Y , Yfin) , tt* ) , w')) = 
            (((X ⊎ Y) , isFinSet⊎ ((X , Xfin)) (Y , Yfin)) , tt*) , rec w w'
        _⨂_ .F-hom {X}{Y}((((f , femb) , _), Δ₁) , (((g , gemb) , _), Δ₂)) = 
            ((map f g , {!   !}) , refl) , funExt λ {(inl x) → {!  Δ₁  !}
                                                    ; (inr x) → {! Δ₂  !}} 
        _⨂_ .F-id = {! refl  !}
        _⨂_ .F-seq = {!  isSetHom !}

        mon : StrictMonStr W
        mon = record { tenstr = 
            record { ─⊗─ = _⨂_ ; 
                        unit = emptymap } ; 
                assoc = {!   !} ; 
                idl = λ{x → ΣPathP ((ΣPathP (ΣPathP ({! lemma  !} , {!   !}) , {!   !})) , {! ΣPathP ?  !})} ; 
                idr = {!   !} }

        strmon : StrictMonCategory (ℓ-suc ℓS) ℓS 
        strmon = record { C = W ; sms = mon }
        
        open import src.Data.Semicartesian

        semimon : SemicartesianStrictMonCat {!   !} {!   !}
        semimon = record { C = W ; sms = mon ; term = emptymap , λ y → ((((λ{()}) , {!  !}) , refl) , {!   !}) , {!   !} ; semi = refl }


        -- Monoid on Values
        open import src.Data.DayConv
        _⨂ᴰᵥ_ : ob 𝒱 → ob 𝒱 → ob 𝒱
        A ⨂ᴰᵥ B = _⊗ᴰ_ {MC = strmon} A B 
        
             