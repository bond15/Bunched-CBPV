{-# OPTIONS --allow-unsolved-metas  --lossy-unification #-}

module src.Models.FuturePast where
    open import Cubical.Foundations.Prelude
    open import Cubical.Foundations.HLevels hiding (extend)
    open import Cubical.Functions.Embedding

    open import Cubical.Categories.Adjoint
    open import Cubical.Categories.Adjoint.Monad
    open import Cubical.Categories.Bifunctor.Redundant
    open import Cubical.Categories.Category
    open import Cubical.Categories.Functor
    open import Cubical.Categories.Functors.Constant
    open import Cubical.Categories.Instances.Discrete
    open import Cubical.Categories.Instances.Functors
    open import Cubical.Categories.Instances.Sets 
    open import Cubical.Categories.Monad.Base
    open import Cubical.Categories.NaturalTransformation
    open import Cubical.Categories.Presheaf.Base
    open import Cubical.Categories.Presheaf.Constructions
    
    open import Cubical.Data.Bool 
    open import Cubical.Data.FinSet
    open import Cubical.Data.FinSet.Constructors
    open import Cubical.Data.FinSet.DecidablePredicate 
    open import Cubical.Data.Nat
    open import Cubical.Data.Sigma
    open import Cubical.Data.Sum
    open import Cubical.Data.Unit

    open import Cubical.HITs.SetQuotients renaming ([_] to q[_])

    open Category
    open Functor

    module Cats {ℓS ℓC ℓC' : Level}(W : Category ℓC ℓC')(isSetWob : isSet (ob W)) where
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


    module Model {ℓS : Level} where 
        open import src.Data.Worlds hiding (Inc)


        data SynTy' : Type ℓS where 
            u n b : SynTy'

        SynTyisSet : isSet SynTy' 
        SynTyisSet = {!  !}

        SynTy : hSet ℓS 
        SynTy = SynTy' , SynTyisSet

        -- top maps are op
        W : Category (ℓ-suc ℓS) ℓS
        W = World SynTy

        _≡tag_ : {w : ob W} → (x y : w .fst .fst .fst) → Bool 
        _≡tag_ {w} x y = isDecProp≡ (w .fst .fst) x y .fst


        _ : isSet (Σ[ X ∈ FinSet ℓS ] Unit* → SynTy')
        _ = isSet→ {A' = SynTy'}{A = Σ[ X ∈ FinSet ℓS ] Unit* } SynTyisSet   
        wset : isSet (ob W)
        wset = isSetΣ (isSetΣ {! isFinSet→isSet !} λ _ → isSetUnit*) λ _ → {!  !}

        open Cats {ℓS} W wset

        open import src.Data.DayConv
        open MonoidalStructure SynTy hiding (W)
        _ = {! src.Data.Worlds.MonoidalStructure  !}
        
        -- semicartesian one for the value category
        open import src.Data.Semicartesian
        _⨂ᴰᵥ_ : ob 𝒱 → ob 𝒱 → ob 𝒱
        A ⨂ᴰᵥ B = _⊗ᴰ_ {MC = strmon} A B 

        _⨂ᴰc_ : ob 𝒞 → ob 𝒞 → ob 𝒞
        A ⨂ᴰc B = _⊗ᴰ_ {MC = strmon ^opMon} A B 

        -- observe action of F on objects
        module _ (A : ob 𝒱)(w₁ : ob W) where 
            -- must provide
            -- a future world w₂
            -- an injection f from w₁ to w₂ 
            -- and an element at that future world
            sig : (w₂ : ob W)(f : W [ w₂ , w₁ ])(a : (A ⟅ w₂ ⟆) .fst) → ((F ⟅ A ⟆) ⟅ w₁ ⟆) .fst 
            sig w₂ f a = w₂ , (f , a)
            -- action of F ⟅ A ⟆ on morphisms
            -- just precomposition of w₂↪w₁
            sigact : (w₂ : ob W)(f : W [ w₁ , w₂ ])→ ((F ⟅ A ⟆) ⟅ w₁ ⟆) .fst → ((F ⟅ A ⟆) ⟅ w₂ ⟆) .fst 
            sigact w₂ w₂↪w₁ (w₃ , w₁↪w₃ , Aw₃ ) = ((F ⟅ A ⟆)⟪ w₂↪w₁ ⟫) (w₃ , (w₁↪w₃ , Aw₃))
            
            
            
        -- observe actions of F on morphism
        module _ (A B : ob 𝒱)(nt : A ⇒ B )(w₁ : ob W) where 

            mor : 𝒞 [ F ⟅ A ⟆ , F ⟅ B ⟆ ]
            mor = F ⟪ nt ⟫

            open NatTrans
            -- in some current world w₁ 
            -- for any future world w₂ of w₁ 
            -- with injection p from 
            act : (w₂ : ob W)(p : W [ w₂ , w₁ ])(a : F-ob A w₂ .fst) → ((F ⟅ B ⟆) .F-ob w₁ ).fst
            act w₂ p a = mor .N-ob w₁ (w₂ , p , a )

        -- utilities
        module _ where 
            -- pattern syntax for ob World
            pattern _◂_ x z = (((x , _), _ ) , z) 
            pattern _◂_◂_ x y z = (((x , y), _ ) , z) 

            UnitF : FinSet ℓS
            UnitF = Unit* , {! !}

            inlemb : {ℓ : Level}{A B : Type ℓ} → isEmbedding (inl {ℓ}{ℓ}{A}{B})
            inlemb = λ w x → record { equiv-proof = λ y → ({!   !} , {!   !}) , (λ y₁ → {!   !}) }
            
            inc : FinSet ℓS → FinSet ℓS
            inc X = ((X .fst ⊎ Unit*) , isFinSet⊎ X UnitF)

            inj : {X Y  : FinSet ℓS}(f : X .fst → Y .fst) → (inc X) .fst → (inc Y) .fst
            inj f (inl x) = inl (f x)
            inj f (inr x) = inr x

            extend' : {X : FinSet ℓS} → (f : X .fst → SynTy')(ty : SynTy') → ((inc X) .fst → SynTy')
            extend' f ty (inl x) = f x
            extend' f ty (inr tt*) = ty

            extend : (ty : SynTy') → ob |W| → ob |W|
            extend ty ((X , tt*) , w) = (inc X , tt*) , extend' {X} w ty

        module _ where 
    
            tys : SynTy' → ob 𝒱
            tys b = Constant _ _ (Lift Bool , isOfHLevelLift 2 isSetBool)  
            tys u = Constant _ _ (Unit* , isOfHLevelLift 2 isSetUnit)  
            tys n = Constant _ _ (Lift ℕ , isOfHLevelLift 2 isSetℕ) 

            OSum : ob 𝒱
            OSum .F-ob (((X , Xfin) , tt* ) , w) = 
                (Σ[ x ∈ X ] ((tys (w x)) ⟅ (((X , Xfin) , _ ) , w) ⟆) .fst) , 
                isSetΣ (isFinSet→isSet Xfin) λ x → ((tys (w x)) ⟅ (((X , Xfin) , _ ) , w) ⟆) .snd
            OSum .F-hom f (x , elem) = f .fst .fst .fst x , {! elem  !}
            OSum .F-id = {!   !}
            OSum .F-seq = {!   !}


            Case : (ty : SynTy') → ob 𝒱
            Case ty .F-ob (X ◂ Xfin ◂ w) = (Σ[ σ ∈ X ] Lift ( w σ ≡ ty)) , {!   !}
            Case ty .F-hom 
                {(((X , Xfin) , tt* ) , w)}
                {(((Y , Yfin) , tt* ) , w')}
                (((f , femb), _) , Δ )  
                (x , wx≡ty ) 
                = f x , transport lemma wx≡ty where 

                    lemma : Lift (w x ≡ ty) ≡ Lift (w' (f x) ≡ ty)
                    lemma = cong Lift (cong ( _≡ ty ) {!  Δ !})
            Case ty .F-id = {!   !}
            Case ty .F-seq = {!   !}

            Termᶜ : ob 𝒞 
            Termᶜ = Constant _ _ (Unit* , isOfHLevelLift 2 isSetUnit)
            
            Termᵛ : ob 𝒱
            Termᵛ = Constant _ _ (Unit* , isOfHLevelLift 2 isSetUnit)

            -- judgements
            value : (Γ A : ob 𝒱) → Set (ℓ-suc ℓS)
            value Γ A = 𝒱 [ Γ , A ]

            -- not quite a morphism in 𝒞 ..
            -- the naturality condition is off
            -- alternatively, could find some way to turn Γ into a computation.. 
            -- besides F?
            record computation (Γ : ob 𝒱)(A : ob 𝒞) : Set (ℓ-suc ℓS) where 
                field 
                    α : ∀ (w : ob W) → (SET ℓ)[ Γ .F-ob w , A .F-ob w ]
                   -- nat : ∀ {w w' : ob W} → (f : W [ w , w' ]) → Γ .F-hom f ⋆⟨ SET ℓ ⟩ α w ⋆⟨ SET ℓ ⟩ A .F-hom f ≡ α w' 

            comp≡ : {Γ : ob 𝒱}{A : ob 𝒞}{c₁ c₂ : computation Γ A} → c₁ .computation.α ≡ c₂ .computation.α → c₁ ≡ c₂
            comp≡ p = cong (λ x → record { α = x }) p

            convert : ob 𝒱 → ob 𝒞 
            convert X = {! X  !}
                -- record { F-ob = X .F-ob ; F-hom = {! X .F-hom  !} ; F-id = {!   !} ; F-seq = {!   !} }

            ret' : {Γ A : ob 𝒱}→ 𝒱 [ Γ , A ] → 𝒞 [ {!  Γ !} , F ⟅ A ⟆ ]
            ret' = {!   !}
            
            ret : {val : ob 𝒱} → 𝒱 [ val , (U ∘F F) ⟅ val ⟆ ]
            ret {val} = natTrans α {! makeNatTransPath ?  !} where 
                α : N-ob-Type val ((U ∘F F) ⟅ val ⟆)
                α w Vw = record { fun = λ w2 f →  w2 , ((W ^op) .id , val .F-hom f Vw) }

                prf : N-hom-Type val ((U ∘F F) ⟅ val ⟆) α
                prf f = {! makeNatTransPath ? !}

        -- denote terms
        module _ where 
            open import Cubical.HITs.SetCoequalizer.Base
            
            -- is this an issue though..?
            _ : 𝒱 [ Termᵛ , Case b ]
            _ = natTrans {!   !} {!   !} where 
                α : N-ob-Type Termᵛ (Case b)
                α w tt* = {!   !} , {!   !}
                -- for an arbitrary X --w--> SynTy
                -- can't choose an x : X for which w(x) ≡ b

            
            conv : 𝒱 [ Case b  ⨂ᴰᵥ Case n , Termᵛ ]
            conv = natTrans {!   !} {!   !} where 
                α : N-ob-Type (Case b ⨂ᴰᵥ Case n) Termᵛ
                α w₀ (SetCoequalizer.inc (((X ◂ _ ◂ wmap) , (Y ◂ _ ◂ wmap')) , (((w₁⊗w₂↪w₀ , ttmap) , Δ) , Case_b_w₁) , Case_n_w₂)) = {!   !}
                α w (coeq a i) = {!   !}
                α w (squash x x₁ p q i i₁) = {!   !}
                
            -- given 
            -- m : 𝒱 [ Γ , Case b ]
            -- p : 𝒱 [ Γ , tys b ]
            -- construct
            -- 𝒱 [ Γ , OSum ]

            injSem' : {Γ : ob 𝒱} → 𝒱 [ Γ , Case b ] → 𝒱 [ Γ , tys b ] → 𝒱 [ Γ , OSum ]
            injSem' {Γ} m p  = ctx ⋆⟨ 𝒱 ⟩ injSem where 

                ctx : 𝒱 [ Γ  , (Case b) ×P (tys b) ]
                ctx = natTrans (λ w γ → (m ⟦ w ⟧)(γ) , (p ⟦ w ⟧)(γ)) {!   !}

                injSem : 𝒱 [ (Case b) ×P (tys b) , OSum ]
                injSem = natTrans α prf where
                
                    α : N-ob-Type (Case b ×P (tys b)) OSum
                    α w ((x , lift wxisb), y) = x , transport eqty y where

                        eqty : (tys b ⟅ w ⟆) .fst ≡ (tys (w .snd x) ⟅ w ⟆) .fst
                        eqty = cong fst (cong₂ _⟅_⟆ (cong tys (sym wxisb)) refl) 

                    prf : N-hom-Type (Case b ×P tys b) OSum α
                    prf f = {!   !}
                -- prf : N-hom-Type (Case b ×P Constant ((W ^op) ^op) (SET ℓ) (Lift Bool , isOfHLevelLift 2 isSetBool)) OSum α
                -- prf {(((X , Xfin) , tt* ) , w)}
                --     {(((Y , Yfin) , tt* ) , w')}
                --     (((f , femb), _) , Δ )  = ? --funExt λ{((x , lift wx≡b) , lift bval) → {!   !} }

            newcase : (ty : SynTy') → 𝒞 [ Termᶜ , F ⟅ Case ty ⟆ ]
            newcase ty = natTrans α {!   !} where 

                w' : ob W → ob W
                w' = extend ty

                w→w' : (w : ob W) → (W ^op) [ w , w' w ]
                w→w' w = (((inl , inlemb) , refl) , refl)

                Case_w : (w : ob W) →  Case ty .F-ob (w' w) .fst
                Case_w _ = (inr tt* , lift refl)

                α : N-ob-Type Termᶜ (F ⟅ Case ty ⟆)
                α w tt* = w' w , (w→w' w , Case_w  w)

            -- simple match
            match : (ty : SynTy') → 𝒱 [ Case ty ×P OSum , tys ty ]
            match ty = natTrans {!   !} {!   !}  where 
                α : N-ob-Type (Case ty ×P OSum) (tys ty)
                α w ((σ , lift wσ≡ty) , (σ' , e∈ty)) = transport lemma e∈ty where 
                
                    assuming : σ ≡ σ'
                    assuming = {!   !}

                    lemma : (tys (w .snd σ') ⟅ w ⟆) .fst ≡ (tys ty ⟅ w ⟆) .fst
                    lemma = {!   !}
                       --cong fst (cong₂ _⟅_⟆ (cong tys (snd w σ' ≡⟨ cong₂ _ refl assuming ⟩ snd w σ ≡⟨ wσ≡ty ⟩ ty ∎)) refl)

            -- function type
            fun : ob 𝒱 → ob 𝒞 → ob 𝒞 
            fun A B .F-ob w = (SET ℓ)[ A .F-ob w , B .F-ob w ] , (SET ℓ) .isSetHom
            fun A B .F-hom f g Ay = (B .F-hom f) (g ((A .F-hom f) Ay)) 
            fun A B .F-id = funExt λ g → {!   !}
               -- _ : (λ Ay → B .F-hom (id W) (g (A .F-hom (id W) Ay))) ≡ (λ Ay → B .F-hom (id W) (g Ay)) ≡ (λ Ay → g Ay)) ≡ g
            fun A B .F-seq f g = funExt λ h → funExt λ Az → {!   !}

            -- fun Intro
            funIntro : {Γ A : ob 𝒱}{B : ob 𝒞} → computation (Γ ×P A) B → computation Γ (fun A B) 
            funIntro {Γ} {A} {B} record { α = α } = record { α = λ w Γw Aw → α w (Γw , Aw) }

            funElim : {Γ Δ A : ob 𝒱}{B : ob 𝒞} → 
                computation Γ (fun A B) → 
                value Δ A → 
                computation (Γ ×P Δ) B 
            funElim record { α = α } (natTrans N-ob N-hom) = record { α = λ{ w (Γw , Δw) → α w Γw (N-ob w Δw) }}

            dup : {A : ob 𝒱} → 𝒱 [ A , A ×P A ]
            dup = natTrans (λ x a → a , a) λ f → refl
            
            bimap : {A B C D : ob 𝒱} → 
                𝒱 [ A , B ] → 
                𝒱 [ C , D ] → 
                𝒱 [ A ×P C , B ×P D ]
            bimap M N = natTrans (λ{w (Aw , Cw) → M .N-ob w Aw , N .N-ob w Cw}) λ f → {! refl  !} where 
                open NatTrans
            
            p₁ : {A₁ A₂ : ob 𝒱} → 𝒱 [ (A₁ ×P A₂) , A₁ ]
            p₁ = natTrans (λ x p → fst p) λ f → refl 

            prodIntro : {Γ  A₁ A₂ : ob 𝒱} → 
                value Γ A₁ → 
                value Γ A₂ → 
                value Γ (A₁ ×P A₂)
            prodIntro M N = dup ⋆⟨ 𝒱 ⟩ bimap M N

            prodElim₁ : {Γ  A₁ A₂ : ob 𝒱} → 
                value Γ (A₁ ×P A₂) → 
                value Γ A₁
            prodElim₁ M = M ⋆⟨ 𝒱 ⟩ p₁

            prodBeta : {Γ  A₁ A₂ : ob 𝒱} → 
                (M : value Γ A₁) → 
                (N : value Γ A₂) → 
                prodElim₁ (prodIntro M N) ≡ M 
            prodBeta M N = makeNatTransPath refl
            
            -- just bilinear map
            sepProdIntro : {Γ Δ A₁ A₂ : ob 𝒱} → 
                value Γ A₁ → 
                value Δ A₂ → 
                value (Γ  ⨂ᴰᵥ Δ) (A₁ ⨂ᴰᵥ A₂) 
            sepProdIntro M N  = Day-Functor strmon .F-hom (M , N)

            sepProdElim₁ : {Γ Δ A₁ A₂ : ob 𝒱} → 
                value (Γ  ⨂ᴰᵥ Δ) (A₁ ⨂ᴰᵥ A₂) → 
                value (Γ  ⨂ᴰᵥ Δ) A₁ 
            sepProdElim₁ M = M ⋆⟨ 𝒱 ⟩ {!   !}  -- semicartesian projection


            sep : ob 𝒱 → ob 𝒞 → ob 𝒞 
                -- should be an end 
            sep A B .F-ob w = (∀ (w' : ob W) → (SET ℓ)[ A .F-ob w' , B .F-ob (_⨂_ .F-ob (w , w')) ]) , isSetΠ  λ _ → (SET ℓ) .isSetHom
            sep A B .F-hom {w₁}{w₂} w₁→w₂ end w₃ Aw₃ = B .F-hom (_⨂_ .F-hom (w₁→w₂ , W .id)) (end w₃ Aw₃)
            sep A B .F-id = {!  !}
            sep A B .F-seq = {!   !}

            sepIntro :  {Γ A : ob 𝒱}{B : ob 𝒞} → computation (Γ ⨂ᴰᵥ A) B → computation Γ (sep A B) 
            sepIntro record { α = α } = record { α = λ w Γw w' Aw' → α (_⨂_ .F-ob (w , w')) (SetCoequalizer.inc ((w , w') , (((((λ x → x) , snd (id↪ _)) , refl) , refl) , Γw) , Aw')) }

            -- morphism in the day convolution is the wrong direction..
            -- day convolution needed in the computation category?
            sepElim : {Γ Δ A : ob 𝒱}{B : ob 𝒞} → 
                computation Γ (sep A B) → 
                value Δ A → 
                computation (Γ ⨂ᴰᵥ Δ) B 
            sepElim {Γ}{Δ}{A}{B} record { α = α } (natTrans N-ob N-hom) = record { α = goal } where 

                goal : (w : ob W) → SET ℓ [ (Γ ⨂ᴰᵥ Δ) .F-ob w , B .F-ob w ] 
                goal w (SetCoequalizer.inc ((w₂ , w₃) , (w→w₂⊗w₃ , Γw₂) , Δw₃)) = goal' where
                    open SemicartesianStrictMonCat semimon
                    -- instead of..
                    --  B .F-hom w₂⊗w₃→w (α w₂ Γw₂ w₃ (N-ob w₃ Δw₃))
                    -- since we don't have w₂⊗w₃→w ..
                    w⊗w→w : W [ (_⨂_ .F-ob (w , w)) , w ]
                    w⊗w→w  = proj₁ 
                    -- This is an arbitrary choice between inl and inr... which feels wrong

                    w→w₂ : W [ w , w₂ ]
                    w→w₂ = w→w₂⊗w₃ ⋆⟨ W ⟩ proj₁

                    w→w₃ : W [ w , w₃ ]
                    w→w₃ = w→w₂⊗w₃ ⋆⟨ W ⟩ proj₂

                    goal' : fst (B .F-ob w)
                    goal' = B .F-hom w⊗w→w  (α w (Γ .F-hom w→w₂ Γw₂) w (N-ob w (Δ .F-hom w→w₃ Δw₃)))
                    
                goal w (coeq ((w₂ , w₃) , (w₄ , w₅) , (w₄→w₂ , w₅→w₃) , (w→w₄⊗w₅ , Γw₂) , Δw₃) i) = goal' where 
                
                    goal' : fst (B .F-ob w)
                    goal' = B .F-hom {! hmm  !} {! α w Γw w Aw!}
                goal w (squash c c₁ p q i i₁) = {!   !} 

            test : {Γ A : ob 𝒱}{B : ob 𝒞} → 
                computation A B → 
                computation (Γ ⨂ᴰᵥ A) B 
            test {Γ}{A}{B} record { α = α } =  record { α = goal }  where 
                goal : (w : ob W) → SET ℓ [ (Γ ⨂ᴰᵥ A) .F-ob w , B .F-ob w ]
                goal w (SetCoequalizer.inc ((w₂ , w₃) , (w→w₂⊗w₃ , Γw₂) , Aw₃)) = α w (A .F-hom w→w₃ Aw₃) where 
                    -- instead of B .F-hom ?? (α w₃ Aw₃)
                    open SemicartesianStrictMonCat semimon
                    w→w₃ : W [ w , w₃ ]
                    w→w₃ = w→w₂⊗w₃ ⋆⟨ W ⟩ proj₂

                goal w (coeq a i) = {!   !}
                goal w (squash c c₁ p q i i₁) = {!   !}

            thunk : {Γ : ob 𝒱}{B : ob 𝒞} → computation Γ B → value Γ (U .F-ob B)
            thunk {Γ}{B} record { α = α } = natTrans (λ{w Γw → record { fun = λ w' f → α w' (Γ .F-hom f Γw) }}) {!   !} 

            return : {Γ A : ob 𝒱} → value Γ A → computation Γ (F .F-ob A) 
            return (natTrans N-ob N-hom) = record { α = λ w Γw → w , W .id , N-ob w Γw }

            OSumElim : {A : SynTy'}{Γ : ob 𝒱}{B : ob 𝒞} → 
                value Γ (Case A) →
                value Γ OSum → 
                computation (Γ ×P tys A) B → 
                computation Γ B → 
                computation Γ B
            OSumElim {A}{Γ}{B}(natTrans Vt N-hom) 
                    (natTrans V N-hom₁) 
                    record { α = M } 
                    record { α = N } = record { α = goal } where 

                        goal : (w : ob W) → (SET ℓ) [ Γ .F-ob w , B .F-ob w ]
                        goal w Γw = goal' where
                            open import Cubical.Foundations.Equiv
                            open import Cubical.Foundations.Isomorphism
                            open Iso
                            
                            osum : fst (OSum .F-ob w)
                            osum = V w Γw

                            case : fst( (Case A) .F-ob w )
                            case = Vt w Γw
                            
                            -- why is this red?
                            -- see src.sandbox... no red there
                            goal' : fst (B .F-ob w)
                            goal' with (isDecProp≡ (w .fst .fst) (case .fst) (osum .fst) )
                            ... | false , _ = N w Γw
                            ... | true , eq = M w (Γw , a) where 
                                eqtag : case .fst ≡ osum .fst 
                                eqtag = equivToIso eq .inv tt

                                prf : (snd w (fst osum)) ≡ A 
                                prf = (snd w (fst osum)) ≡⟨ cong (λ x → snd w x) (sym eqtag) ⟩ 
                                      (snd w (fst case)) ≡⟨ case .snd .lower ⟩ 
                                      A ∎

                                eqty : ((tys (snd w (fst osum)) ) .F-ob w) .fst ≡ ((tys A) .F-ob w) .fst
                                eqty = cong (λ x → fst ((tys x) .F-ob w)) prf

                                a : fst (F-ob (tys A) w)
                                a = transport eqty (osum .snd)   
            
        module concreteExamples where

            data w1 : Set ℓS where  
                σ₁ : w1 
            
            data w2 : Set ℓS where 
                σ₁ σ₂ : w2
                
            w₁ : ob W 
            w₁ = ((w1 , {!   !}) , tt*) , λ{ σ₁ → b}
            
            w₂ : ob W 
            w₂ = ((w2 , {!   !}) , tt*) , λ{ σ₁ → b
                                           ;   σ₂ → b}

            --_ : fst( (sep (Case n) (F .F-ob OSum)) .F-ob w₁)
           -- _ = λ w' → λ{ (σ₁ , lift (w₁σ₁≡n)) → {!   !}}  -- false

            
            --_ : 𝒞 [ Termᶜ , sep (Case b) (F . F-ob (tys b)) ]
            --_ = natTrans (λ w tm → λ w' → λ{(x , wx≡b) → {!   !} , {!   !} , {!   !}}) {!   !}



     


    
     
      