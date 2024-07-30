{-# OPTIONS --allow-unsolved-metas #-}

module src.Data.BCBPV where 
    open import Cubical.Foundations.HLevels hiding (extend)
    open import Cubical.Foundations.Prelude  
    open import Cubical.Categories.Category
    open import Cubical.Categories.Functor
    open import Cubical.Categories.Instances.Functors
    open import Cubical.Categories.Instances.Sets
    open import Cubical.Categories.NaturalTransformation
    open import Cubical.Categories.Functors.Constant
    open import Cubical.Categories.Presheaf.Base
    open import Cubical.Categories.Presheaf.Constructions
    open import Cubical.Categories.Bifunctor.Redundant hiding (Fst)
    open import Cubical.Categories.Monoidal.Base
    open import src.Data.DayConv
    open import Cubical.Foundations.Isomorphism
    open import Cubical.Data.Sigma 
    open import Cubical.HITs.SetCoequalizer
    open import src.Data.Coend
    open import Cubical.Categories.Constructions.BinProduct renaming (_×C_ to _B×C_)
    open import src.Data.PresheafCCC
    open import Cubical.Categories.Yoneda.More
    open import Cubical.Foundations.Function
    open import Cubical.Data.Sigma 
    open import Cubical.Categories.Instances.Discrete
    
    open Category

    module Mod {ℓ ℓ' : Level}(SMC : StrictMonCategory ℓ ℓ')(isGrpCob : isGroupoid (ob (StrictMonCategory.C SMC))) where
        open import src.Data.BiDCC 
        open Mod SMC
        open StrictMonCategory SMC renaming(─⊗─ to ⨂c) hiding (ob)
        open Functor
        open Bifunctor
        open NatTrans
        open BifunctorPar

        _ = {! StrictMonCategory.C SMC !}
        𝓒 : Category (ℓ-suc ℓm) ℓm 
        𝓒 = PresheafCategory (C ^op) ℓm



        open import src.Data.Direct2

        |C| : Category ℓ ℓ
        |C| = (DiscreteCategory (ob C , isGrpCob))
        
        Inc : Functor |C| C
        Inc = DiscFunc λ x → x
        
        Fam : Category (ℓ-suc ℓm) ℓm
        Fam = FUNCTOR |C| (SET ℓm)

        Inc* : Functor 𝓒 Fam 
        Inc* = precomposeF (SET ℓm) (Inc)

        open Ran C isGrpCob hiding (Inc* ; Inc)
        open End renaming (fun to end)

        U' : Functor Fam 𝓥
        U' = Ran

        U : Functor 𝓒 𝓥 
        U = U' ∘F  Inc* 

        open Lan (C ^op) isGrpCob hiding (Inc* ; Inc)

        F' : Functor Fam 𝓒 
        F' = Lan

        F : Functor 𝓥 𝓒 
        F = Lan ∘F precomposeF (SET ℓm) (DiscFunc λ x → x)

        open import Cubical.Foundations.Function
        
        𝓞' : BifunctorPar (𝓥 ^op) 𝓒 (SET ℓm) 
        𝓞' .Bif-ob v c = (∀ (x : ob C) → v .F-ob x .fst  → c .F-ob x .fst) , isSetΠ λ x → isSet→ (c .F-ob x .snd) 
        𝓞' .Bif-hom× f g m x = (g .N-ob x ∘S m x) ∘S f .N-ob x 
        𝓞' .Bif-×-id = refl 
        𝓞' .Bif-×-seq f₁ f₂ g₁ g₂ = refl 
        
        𝓞 : Bifunctor (𝓥 ^op) 𝓒 (SET ℓm) 
        𝓞 = mkBifunctorPar 𝓞'

        -- oblique morphisms
        𝓞[_,_] : ob 𝓥 → ob 𝓒 → Set ℓm
        𝓞[ v , c ] = (𝓞 .Bif-ob v c) .fst

        open import Cubical.Categories.Adjoint
        open AdjointUniqeUpToNatIso 
        open NaturalBijection
        open _⊣_

        -- the existence of these isomorphisms are mentioned on page 210 of Levy's thesis
        ob₁ : {P : ob 𝓥}{Q : ob 𝓒} → Iso (𝓥 [ P , U .F-ob Q ]) 𝓞[ P , Q ] 
        ob₁ {P} {Q} = iso 
                        (λ nt x Px → nt .N-ob x Px .end x (C .id)) 
                        (λ o → natTrans (λ x Px → record { fun = λ y y→x → o y (P .F-hom y→x Px) }) 
                                λ f  → funExt λ Px → end≡ (Q ∘F Inc) λ z z→y → cong (λ h → o z h) 
                                    (funExt⁻ (sym (P .F-seq _ _))_)) 
                        (λ b  → funExt λ x → funExt λ Px → cong (λ h → b x h ) (funExt⁻ (P .F-id) _)) 
                        λ b → makeNatTransPath (funExt λ x → funExt λ Px → end≡  ((Q ∘F Inc)) λ y y→x  →
                                cong (λ h → h .Ran.End.fun y (C .id)) (funExt⁻ (b .N-hom y→x) Px) 
                                ∙ cong (λ h → b .N-ob x Px .Ran.End.fun y h) (C .⋆IdL _))

        ob₂ : {P : ob 𝓥}{Q : ob 𝓒} → Iso 𝓞[ P , Q ] (𝓒 [ F .F-ob P , Q ]) 
        ob₂ {P}{Q}= iso 
                (λ o → natTrans (λ{x (y , (y→x , Py)) → Q .F-hom y→x (o y Py)}) 
                        λ f → funExt λ{(z , (z→x , Pz)) → funExt⁻ (Q .F-seq _ _ ) _}) 
                (λ nt x Px → nt .N-ob x (x , ((C .id) , Px))) 
                (λ b → makeNatTransPath (funExt λ x → funExt λ{(y , (y→x , Py)) → 
                    funExt⁻ (sym (b .N-hom y→x)) _ 
                    ∙ cong (λ h → b .N-ob x h) (ΣPathP (refl , (ΣPathP ((C .⋆IdL _) , refl))))})) 
                λ b → funExt λ x → funExt λ Px → funExt⁻ (Q .F-id) _

        adjhom : {X : ob 𝓥}{Y : ob 𝓒} → Iso (𝓥 [ X , U .F-ob Y ]) (𝓒 [ F .F-ob X , Y ])
        adjhom = compIso ob₁ ob₂

        F⊣U : F ⊣ U 
        F⊣U .adjIso = invIso adjhom 
        F⊣U .adjNatInD _ _ = makeNatTransPath (funExt λ _ → funExt λ _ → refl) 
        F⊣U .adjNatInC _ _ = makeNatTransPath (funExt λ _ → funExt λ _ → refl) 

        𝓞× : ob 𝓥 → ob 𝓥 → ob 𝓒 → Set ℓm
        𝓞× v₁ v₂ c = ∀ (x y : ob C) → v₁ .F-ob x .fst × v₂ .F-ob y .fst → c .F-ob (⨂c .F-ob (x , y)) .fst

        -- looks like you can't define the ⨂UP for oblique morphisms here?
        module attempt where
            frwd :{P Q : ob 𝓥}{R : ob 𝓒} → 𝓞[ P ⨂ᴰ Q , R ] → 𝓞× P Q R 
            frwd {P}{Q}{R} o x y (Px , Qy) = o (⨂c .F-ob (x , y)) (inc ((x , y) , (((C .id) , Px) , Qy)))
            
            open Iso renaming (fun to fun')
            open DayUP
            open UniversalProperty
            
            -- looks like you can't define this ..?
            -- at least for an opaque category C .. what if things are concrete?
            bkd : {P Q : ob 𝓥}{R : ob 𝓒} → 𝓞× P Q R → 𝓞[ P ⨂ᴰ Q , R ]
            bkd {P}{Q}{R} o x = 
                inducedHom 
                    (R .F-ob x .snd) 
                    -- same issue , have R(x ⊗c y) and z→x⊗y but need R(z) 
                    -- and R is covariant..
                    (λ{((y , z) , (x→y⊗z , Py) , Qz) → {! o y z (Py , Qz)  !}}) 
                    {!   !}
                --ob₁ {P ⨂ᴰ Q}{R} .fun' (⨂UP {P}{Q}{U .F-ob R} .inv (natTrans (λ{(x , y)(Px , Qy) → record { fun = λ z z→x⊗y → {! o x y (Px , Qy)  !} }}) {!   !})) 
            
            ⨂UP𝓞 : {P Q : ob 𝓥}{R : ob 𝓒} → Iso 𝓞[ P ⨂ᴰ Q , R ] (𝓞× P Q R) 
            ⨂UP𝓞 {P}{Q}{R} = 
                iso 
                    (frwd {P}{Q}{R})
                    (bkd {P}{Q}{R}) 
                    {!   !} 
                    {!   !}

        -- computational function type
        -- TODO feed seq
        fun : ob 𝓥 → ob 𝓒 → ob 𝓒 
        fun A B .F-ob w = (SET ℓm)[ A .F-ob w , B .F-ob w ] , (SET ℓm) .isSetHom
        fun A B .F-hom f g Ay = (B .F-hom f) (g ((A .F-hom f) Ay)) 
        fun A B .F-id = funExt λ g → funExt λ a → 
            B .F-hom (id C) (g (A .F-hom (id C) a)) ≡⟨ funExt⁻  (B .F-id) _ ⟩
            (g (A .F-hom (id C) a)) ≡⟨ cong g (funExt⁻ (A .F-id) _) ⟩ 
            g a ∎
        fun A B .F-seq f g = funExt λ h → funExt λ Az → funExt⁻ (B .F-seq f g) _ ∙ 
            cong (λ x → seq' (SET ℓm) (F-hom B f) (F-hom B g) (h x)) (funExt⁻ (A .F-seq _ _) _)


        _×p_ : ob 𝓥 → ob 𝓥 → ob 𝓥 
        _×p_ A B = PshProd .Bif-ob A B

        module funUP {P Q : ob 𝓥}{R : ob 𝓒} where 
            
            funIntro : 𝓞[ P ×p Q , R ] → 𝓞[ P , fun Q R ] 
            funIntro f = λ x Px Qx → f x (Px , Qx)

            funIntroInv : 𝓞[ P , fun Q R ] → 𝓞[ P ×p Q , R ] 
            funIntroInv f = λ{x (Px , Qx) → f x Px Qx}

            -- fun up
            →UP : Iso (𝓞[ P ×p Q , R ]) (𝓞[ P , fun Q R ])
            →UP = iso 
                        funIntro 
                        funIntroInv 
                        (λ b → refl)
                        (λ b → refl)


        sep : ob 𝓥 → ob 𝓒 → ob 𝓒 
        -- should be an end ?
        sep A B .F-ob w = (∀ (w' : ob C) → (SET ℓm)[ A .F-ob w' , B .F-ob (⨂c .F-ob (w , w')) ]) , isSetΠ  λ _ → (SET ℓm) .isSetHom
        sep A B .F-hom {w₁}{w₂} w₁→w₂ end w₃ Aw₃ = B .F-hom (⨂c .F-hom (w₁→w₂ , C .id)) (end w₃ Aw₃)
        sep A B .F-id = funExt λ end → funExt λ w₃  → funExt λ Aw₃ → cong (λ x → (B .F-hom x) (end w₃ Aw₃) ) (⨂c .F-id) ∙ funExt⁻ (B .F-id) ((end w₃ Aw₃))
        sep A B .F-seq f g = funExt λ end → funExt λ w₃  → funExt λ Aw₃ → cong (λ h → B .F-hom h _) 
            ( cong (λ h → ⨂c .F-hom h) (≡-× refl (sym (C .⋆IdL _))) ∙ (⨂c .F-seq _ _)) 
            ∙ funExt⁻ ( (B .F-seq (⨂c .F-hom (f , C .id)) (⨂c .F-hom (g , C .id)))) (end w₃ Aw₃)

        module cbpvSepUP {P Q : ob 𝓥}{R : ob 𝓒}where                         
            open Iso renaming (fun to fun')
            open DayUP

            test : 𝓥× [ P ⨂Ext Q , U .F-ob R ∘F (⨂c ^opF) ] → 𝓥 [ P , U .F-ob (sep Q R) ]
            test nt = natTrans η' η'com where
                η' : N-ob-Type P (U .F-ob (sep Q R)) 
                η' x Px = record { fun = λ y y→x z Qz → nt .N-ob (y , z) (P .F-hom y→x Px , Qz) .end (⨂c .F-ob (y , z)) (C .id) } 

                η'com : N-hom-Type P (U .F-ob (sep Q R)) η' 
                η'com f = funExt λ Px → end≡ ((sep Q R) ∘F Inc) λ z z→y  → 
                    funExt λ w → funExt λ Qw → 
                    cong (λ h → nt .N-ob (z , w) (h , Qw) .Ran.End.fun (⨂c .F-ob (z , w)) (C .id) ) (funExt⁻ (sym(P .F-seq f z→y )) Px)


            eval : 𝓥× [ (U .F-ob (sep Q R)) ⨂Ext Q , U .F-ob R ∘F (⨂c ^opF) ] 
            eval .N-ob (x , y) (UQ→Rx , Qy) .end z z→x⊗y = goal where 
                goal : R .F-ob z .fst
                goal = {!   !}
                
                have : R .F-ob (⨂c .F-ob (x , y)) .fst 
                have = UQ→Rx .end x (C .id) y Qy

                cantuse : SET ℓm [ F-ob R z , F-ob R ((⨂c ^opF) ⟅ x , y ⟆) ]
                cantuse = R .F-hom z→x⊗y
                _ = {! UQ→Rx .end  !}
                
            eval .N-hom = {!   !}

            testInv : 𝓥 [ P , U .F-ob (sep Q R) ] → 𝓥× [ P ⨂Ext Q , U .F-ob R ∘F (⨂c ^opF) ]
            testInv nt = ⨂ext .F-hom (nt , (𝓥 .id)) ⋆⟨ 𝓥× ⟩ eval
            
            goal : Iso (𝓥× [ P ⨂Ext Q , U .F-ob R ∘F (⨂c ^opF) ]) (𝓥 [ P , U .F-ob (sep Q R) ])
            goal = iso 
                    test
                    -- (λ nt → natTrans (λ x Px → record { fun = λ y y→x z Qz → {!  nt .N-ob (x , z) (Px , Qz) .end z !} }) {!   !}) 
                    testInv 
                    {!   !} 
                    {!   !}


            ⊸UP' : Iso (𝓥 [ P ⨂ᴰ Q , U .F-ob R ]) (𝓥 [ P , U .F-ob (sep Q R) ] )
            ⊸UP' = compIso ⨂UP goal

            ⊸UP : Iso 𝓞[ P ⨂ᴰ Q , R ] 𝓞[ P , sep Q R ] 
            ⊸UP = compIso (invIso(ob₁ {P ⨂ᴰ Q }{R})) (compIso ⊸UP' (ob₁ {P}{sep Q R}))
