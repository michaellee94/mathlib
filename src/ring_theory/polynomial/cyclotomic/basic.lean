/-
Copyright (c) 2020 Riccardo Brasca. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Riccardo Brasca
-/

import algebra.ne_zero
import algebra.polynomial.big_operators
import ring_theory.roots_of_unity.complex
import data.polynomial.lifts
import data.polynomial.splits
import data.zmod.algebra
import field_theory.ratfunc
import field_theory.separable
import number_theory.arithmetic_function
import ring_theory.roots_of_unity.basic

/-!
# Cyclotomic polynomials.

> THIS FILE IS SYNCHRONIZED WITH MATHLIB4.
> Any changes to this file require a corresponding PR to mathlib4.

For `n : ℕ` and an integral domain `R`, we define a modified version of the `n`-th cyclotomic
polynomial with coefficients in `R`, denoted `cyclotomic' n R`, as `∏ (X - μ)`, where `μ` varies
over the primitive `n`th roots of unity. If there is a primitive `n`th root of unity in `R` then
this the standard definition. We then define the standard cyclotomic polynomial `cyclotomic n R`
with coefficients in any ring `R`.

## Main definition

* `cyclotomic n R` : the `n`-th cyclotomic polynomial with coefficients in `R`.

## Main results

* `polynomial.degree_cyclotomic` : The degree of `cyclotomic n` is `totient n`.
* `polynomial.prod_cyclotomic_eq_X_pow_sub_one` : `X ^ n - 1 = ∏ (cyclotomic i)`, where `i`
  divides `n`.
* `polynomial.cyclotomic_eq_prod_X_pow_sub_one_pow_moebius` : The Möbius inversion formula for
  `cyclotomic n R` over an abstract fraction field for `R[X]`.

## Implementation details

Our definition of `cyclotomic' n R` makes sense in any integral domain `R`, but the interesting
results hold if there is a primitive `n`-th root of unity in `R`. In particular, our definition is
not the standard one unless there is a primitive `n`th root of unity in `R`. For example,
`cyclotomic' 3 ℤ = 1`, since there are no primitive cube roots of unity in `ℤ`. The main example is
`R = ℂ`, we decided to work in general since the difficulties are essentially the same.
To get the standard cyclotomic polynomials, we use `int_coeff_of_cycl`, with `R = ℂ`, to get a
polynomial with integer coefficients and then we map it to `R[X]`, for any ring `R`.
To prove `cyclotomic.irreducible`, the irreducibility of `cyclotomic n ℤ`, we show in
`cyclotomic_eq_minpoly` that `cyclotomic n ℤ` is the minimal polynomial of any `n`-th primitive root
of unity `μ : K`, where `K` is a field of characteristic `0`.
-/

open_locale classical big_operators polynomial
noncomputable theory

universe u

namespace polynomial

section cyclotomic'

section is_domain

variables {R : Type*} [comm_ring R] [is_domain R]

/-- The modified `n`-th cyclotomic polynomial with coefficients in `R`, it is the usual cyclotomic
polynomial if there is a primitive `n`-th root of unity in `R`. -/
def cyclotomic' (n : ℕ) (R : Type*) [comm_ring R] [is_domain R] : R[X] :=
∏ μ in primitive_roots n R, (X - C μ)

/-- The zeroth modified cyclotomic polyomial is `1`. -/
@[simp] lemma cyclotomic'_zero
  (R : Type*) [comm_ring R] [is_domain R] : cyclotomic' 0 R = 1 :=
by simp only [cyclotomic', finset.prod_empty, primitive_roots_zero]

/-- The first modified cyclotomic polyomial is `X - 1`. -/
@[simp] lemma cyclotomic'_one
  (R : Type*) [comm_ring R] [is_domain R] : cyclotomic' 1 R = X - 1 :=
begin
  simp only [cyclotomic', finset.prod_singleton, ring_hom.map_one,
  is_primitive_root.primitive_roots_one]
end

/-- The second modified cyclotomic polyomial is `X + 1` if the characteristic of `R` is not `2`. -/
@[simp] lemma cyclotomic'_two
  (R : Type*) [comm_ring R] [is_domain R] (p : ℕ) [char_p R p] (hp : p ≠ 2) :
  cyclotomic' 2 R = X + 1 :=
begin
  rw [cyclotomic'],
  have prim_root_two : primitive_roots 2 R = {(-1 : R)},
  { simp only [finset.eq_singleton_iff_unique_mem, mem_primitive_roots two_pos],
    exact ⟨is_primitive_root.neg_one p hp, λ x, is_primitive_root.eq_neg_one_of_two_right⟩ },
  simp only [prim_root_two, finset.prod_singleton, ring_hom.map_neg, ring_hom.map_one,
  sub_neg_eq_add]
end

/-- `cyclotomic' n R` is monic. -/
lemma cyclotomic'.monic
  (n : ℕ) (R : Type*) [comm_ring R] [is_domain R] : (cyclotomic' n R).monic :=
monic_prod_of_monic _ _ $ λ z hz, monic_X_sub_C _

/-- `cyclotomic' n R` is different from `0`. -/
lemma cyclotomic'_ne_zero
  (n : ℕ) (R : Type*) [comm_ring R] [is_domain R] : cyclotomic' n R ≠ 0 :=
(cyclotomic'.monic n R).ne_zero

/-- The natural degree of `cyclotomic' n R` is `totient n` if there is a primitive root of
unity in `R`. -/
lemma nat_degree_cyclotomic' {ζ : R} {n : ℕ} (h : is_primitive_root ζ n) :
  (cyclotomic' n R).nat_degree = nat.totient n :=
begin
  rw [cyclotomic'],
  rw nat_degree_prod (primitive_roots n R) (λ (z : R), (X - C z)),
  simp only [is_primitive_root.card_primitive_roots h, mul_one,
  nat_degree_X_sub_C,
  nat.cast_id, finset.sum_const, nsmul_eq_mul],
  intros z hz,
  exact X_sub_C_ne_zero z
end

/-- The degree of `cyclotomic' n R` is `totient n` if there is a primitive root of unity in `R`. -/
lemma degree_cyclotomic' {ζ : R} {n : ℕ} (h : is_primitive_root ζ n) :
  (cyclotomic' n R).degree = nat.totient n :=
by simp only [degree_eq_nat_degree (cyclotomic'_ne_zero n R), nat_degree_cyclotomic' h]

/-- The roots of `cyclotomic' n R` are the primitive `n`-th roots of unity. -/
lemma roots_of_cyclotomic (n : ℕ) (R : Type*) [comm_ring R] [is_domain R] :
  (cyclotomic' n R).roots = (primitive_roots n R).val :=
by { rw cyclotomic', exact roots_prod_X_sub_C (primitive_roots n R) }

/-- If there is a primitive `n`th root of unity in `K`, then `X ^ n - 1 = ∏ (X - μ)`, where `μ`
varies over the `n`-th roots of unity. -/
lemma X_pow_sub_one_eq_prod {ζ : R} {n : ℕ} (hpos : 0 < n) (h : is_primitive_root ζ n) :
  X ^ n - 1 = ∏ ζ in nth_roots_finset n R, (X - C ζ) :=
begin
  rw [nth_roots_finset, ← multiset.to_finset_eq (is_primitive_root.nth_roots_nodup h)],
  simp only [finset.prod_mk, ring_hom.map_one],
  rw [nth_roots],
  have hmonic : (X ^ n - C (1 : R)).monic := monic_X_pow_sub_C (1 : R) (ne_of_lt hpos).symm,
  symmetry,
  apply prod_multiset_X_sub_C_of_monic_of_roots_card_eq hmonic,
  rw [@nat_degree_X_pow_sub_C R _ _ n 1, ← nth_roots],
  exact is_primitive_root.card_nth_roots h
end

end is_domain

section field

variables {K : Type*} [field K]

/-- `cyclotomic' n K` splits. -/
lemma cyclotomic'_splits (n : ℕ) : splits (ring_hom.id K) (cyclotomic' n K) :=
begin
  apply splits_prod (ring_hom.id K),
  intros z hz,
  simp only [splits_X_sub_C (ring_hom.id K)]
end

/-- If there is a primitive `n`-th root of unity in `K`, then `X ^ n - 1`splits. -/
lemma X_pow_sub_one_splits {ζ : K} {n : ℕ} (h : is_primitive_root ζ n) :
  splits (ring_hom.id K) (X ^ n - C (1 : K)) :=
by rw [splits_iff_card_roots, ← nth_roots, is_primitive_root.card_nth_roots h,
    nat_degree_X_pow_sub_C]

/-- If there is a primitive `n`-th root of unity in `K`, then
`∏ i in nat.divisors n, cyclotomic' i K = X ^ n - 1`. -/
lemma prod_cyclotomic'_eq_X_pow_sub_one {K : Type*} [comm_ring K] [is_domain K] {ζ : K} {n : ℕ}
  (hpos : 0 < n) (h : is_primitive_root ζ n) : ∏ i in nat.divisors n, cyclotomic' i K = X ^ n - 1 :=
have hd : (n.divisors : set ℕ).pairwise_disjoint (λ k, primitive_roots k K),
  from λ x hx y hy hne, is_primitive_root.disjoint hne,
by simp only [X_pow_sub_one_eq_prod hpos h, cyclotomic', ← finset.prod_bUnion hd,
    h.nth_roots_one_eq_bUnion_primitive_roots]

/-- If there is a primitive `n`-th root of unity in `K`, then
`cyclotomic' n K = (X ^ k - 1) /ₘ (∏ i in nat.proper_divisors k, cyclotomic' i K)`. -/
lemma cyclotomic'_eq_X_pow_sub_one_div {K : Type*} [comm_ring K] [is_domain K] {ζ : K} {n : ℕ}
  (hpos : 0 < n) (h : is_primitive_root ζ n) :
  cyclotomic' n K = (X ^ n - 1) /ₘ (∏ i in nat.proper_divisors n, cyclotomic' i K) :=
begin
  rw [←prod_cyclotomic'_eq_X_pow_sub_one hpos h, ← nat.cons_self_proper_divisors hpos.ne',
    finset.prod_cons],
  have prod_monic : (∏ i in nat.proper_divisors n, cyclotomic' i K).monic,
  { apply monic_prod_of_monic,
    intros i hi,
    exact cyclotomic'.monic i K },
  rw (div_mod_by_monic_unique (cyclotomic' n K) 0 prod_monic _).1,
  simp only [degree_zero, zero_add],
  refine ⟨by rw mul_comm, _⟩,
  rw [bot_lt_iff_ne_bot],
  intro h,
  exact monic.ne_zero prod_monic (degree_eq_bot.1 h)
end

/-- If there is a primitive `n`-th root of unity in `K`, then `cyclotomic' n K` comes from a
monic polynomial with integer coefficients. -/
lemma int_coeff_of_cyclotomic' {K : Type*} [comm_ring K] [is_domain K] {ζ : K} {n : ℕ}
  (h : is_primitive_root ζ n) :
  (∃ (P : ℤ[X]), map (int.cast_ring_hom K) P = cyclotomic' n K ∧
    P.degree = (cyclotomic' n K).degree ∧ P.monic) :=
begin
  refine lifts_and_degree_eq_and_monic _ (cyclotomic'.monic n K),
  induction n using nat.strong_induction_on with k ihk generalizing ζ h,
  rcases k.eq_zero_or_pos with rfl|hpos,
  { use 1,
    simp only [cyclotomic'_zero, coe_map_ring_hom, polynomial.map_one] },
  let B : K[X] := ∏ i in nat.proper_divisors k, cyclotomic' i K,
  have Bmo : B.monic,
  { apply monic_prod_of_monic,
    intros i hi,
    exact (cyclotomic'.monic i K) },
  have Bint : B ∈ lifts (int.cast_ring_hom K),
  { refine subsemiring.prod_mem (lifts (int.cast_ring_hom K)) _,
    intros x hx,
    have xsmall := (nat.mem_proper_divisors.1 hx).2,
    obtain ⟨d, hd⟩ := (nat.mem_proper_divisors.1 hx).1,
    rw [mul_comm] at hd,
    exact ihk x xsmall (h.pow hpos hd) },
  replace Bint := lifts_and_degree_eq_and_monic Bint Bmo,
  obtain ⟨B₁, hB₁, hB₁deg, hB₁mo⟩ := Bint,
  let Q₁ : ℤ[X] := (X ^ k - 1) /ₘ B₁,
  have huniq : 0 + B * cyclotomic' k K = X ^ k - 1 ∧ (0 : K[X]).degree < B.degree,
  { split,
    { rw [zero_add, mul_comm, ← prod_cyclotomic'_eq_X_pow_sub_one hpos h,
         ← nat.cons_self_proper_divisors hpos.ne', finset.prod_cons] },
    { simpa only [degree_zero, bot_lt_iff_ne_bot, ne.def, degree_eq_bot] using Bmo.ne_zero } },
  replace huniq := div_mod_by_monic_unique (cyclotomic' k K) (0 : K[X]) Bmo huniq,
  simp only [lifts, ring_hom.mem_srange],
  use Q₁,
  rw [coe_map_ring_hom, (map_div_by_monic (int.cast_ring_hom K) hB₁mo), hB₁, ← huniq.1],
  simp
end

/-- If `K` is of characteristic `0` and there is a primitive `n`-th root of unity in `K`,
then `cyclotomic n K` comes from a unique polynomial with integer coefficients. -/
lemma unique_int_coeff_of_cycl {K : Type*} [comm_ring K] [is_domain K] [char_zero K] {ζ : K}
  {n : ℕ+} (h : is_primitive_root ζ n) :
  (∃! (P : ℤ[X]), map (int.cast_ring_hom K) P = cyclotomic' n K) :=
begin
  obtain ⟨P, hP⟩ := int_coeff_of_cyclotomic' h,
  refine ⟨P, hP.1, λ Q hQ, _⟩,
  apply (map_injective (int.cast_ring_hom K) int.cast_injective),
  rw [hP.1, hQ]
end

end field

end cyclotomic'

section cyclotomic

/-- The `n`-th cyclotomic polynomial with coefficients in `R`. -/
def cyclotomic (n : ℕ) (R : Type*) [ring R] : R[X] :=
if h : n = 0 then 1 else
  map (int.cast_ring_hom R) ((int_coeff_of_cyclotomic' (complex.is_primitive_root_exp n h)).some)

lemma int_cyclotomic_rw {n : ℕ} (h : n ≠ 0) :
  cyclotomic n ℤ = (int_coeff_of_cyclotomic' (complex.is_primitive_root_exp n h)).some :=
begin
  simp only [cyclotomic, h, dif_neg, not_false_iff],
  ext i,
  simp only [coeff_map, int.cast_id, eq_int_cast]
end

/-- `cyclotomic n R` comes from `cyclotomic n ℤ`. -/
lemma map_cyclotomic_int (n : ℕ) (R : Type*) [ring R] :
  map (int.cast_ring_hom R) (cyclotomic n ℤ) = cyclotomic n R :=
begin
  by_cases hzero : n = 0,
  { simp only [hzero, cyclotomic, dif_pos, polynomial.map_one] },
  simp only [cyclotomic, int_cyclotomic_rw, hzero, ne.def, dif_neg, not_false_iff]
end

lemma int_cyclotomic_spec (n : ℕ) : map (int.cast_ring_hom ℂ) (cyclotomic n ℤ) = cyclotomic' n ℂ ∧
  (cyclotomic n ℤ).degree = (cyclotomic' n ℂ).degree ∧ (cyclotomic n ℤ).monic  :=
begin
  by_cases hzero : n = 0,
  { simp only [hzero, cyclotomic, degree_one, monic_one, cyclotomic'_zero, dif_pos,
  eq_self_iff_true, polynomial.map_one, and_self] },
  rw int_cyclotomic_rw hzero,
  exact (int_coeff_of_cyclotomic' (complex.is_primitive_root_exp n hzero)).some_spec
end

lemma int_cyclotomic_unique {n : ℕ} {P : ℤ[X]} (h : map (int.cast_ring_hom ℂ) P =
  cyclotomic' n ℂ) : P = cyclotomic n ℤ :=
begin
  apply map_injective (int.cast_ring_hom ℂ) int.cast_injective,
  rw [h, (int_cyclotomic_spec n).1]
end

/-- The definition of `cyclotomic n R` commutes with any ring homomorphism. -/
@[simp] lemma map_cyclotomic (n : ℕ) {R S : Type*} [ring R] [ring S] (f : R →+* S) :
  map f (cyclotomic n R) = cyclotomic n S :=
begin
  rw [←map_cyclotomic_int n R, ←map_cyclotomic_int n S, map_map],
  congr
end

lemma cyclotomic.eval_apply {R S : Type*} (q : R) (n : ℕ) [ring R] [ring S] (f : R →+* S) :
  eval (f q) (cyclotomic n S) = f (eval q (cyclotomic n R)) :=
by rw [← map_cyclotomic n f, eval_map, eval₂_at_apply]

/-- The zeroth cyclotomic polyomial is `1`. -/
@[simp] lemma cyclotomic_zero (R : Type*) [ring R] : cyclotomic 0 R = 1 :=
by simp only [cyclotomic, dif_pos]

/-- The first cyclotomic polyomial is `X - 1`. -/
@[simp] lemma cyclotomic_one (R : Type*) [ring R] : cyclotomic 1 R = X - 1 :=
begin
  have hspec : map (int.cast_ring_hom ℂ) (X - 1) = cyclotomic' 1 ℂ,
  { simp only [cyclotomic'_one, pnat.one_coe, map_X, polynomial.map_one, polynomial.map_sub] },
  symmetry,
  rw [←map_cyclotomic_int, ←(int_cyclotomic_unique hspec)],
  simp only [map_X, polynomial.map_one, polynomial.map_sub]
end

/-- `cyclotomic n` is monic. -/
lemma cyclotomic.monic (n : ℕ) (R : Type*) [ring R] : (cyclotomic n R).monic :=
begin
  rw ←map_cyclotomic_int,
  exact (int_cyclotomic_spec n).2.2.map _,
end

/-- `cyclotomic n` is primitive. -/
lemma cyclotomic.is_primitive (n : ℕ) (R : Type*) [comm_ring R] : (cyclotomic n R).is_primitive :=
(cyclotomic.monic n R).is_primitive

/-- `cyclotomic n R` is different from `0`. -/
lemma cyclotomic_ne_zero (n : ℕ) (R : Type*) [ring R] [nontrivial R] : cyclotomic n R ≠ 0 :=
(cyclotomic.monic n R).ne_zero

/-- The degree of `cyclotomic n` is `totient n`. -/
lemma degree_cyclotomic (n : ℕ) (R : Type*) [ring R] [nontrivial R] :
  (cyclotomic n R).degree = nat.totient n :=
begin
  rw ←map_cyclotomic_int,
  rw degree_map_eq_of_leading_coeff_ne_zero (int.cast_ring_hom R) _,
  { cases n with k,
    { simp only [cyclotomic, degree_one, dif_pos, nat.totient_zero, with_top.coe_zero]},
      rw [←degree_cyclotomic' (complex.is_primitive_root_exp k.succ (nat.succ_ne_zero k))],
      exact (int_cyclotomic_spec k.succ).2.1 },
  simp only [(int_cyclotomic_spec n).right.right, eq_int_cast, monic.leading_coeff,
  int.cast_one, ne.def, not_false_iff, one_ne_zero]
end

/-- The natural degree of `cyclotomic n` is `totient n`. -/
lemma nat_degree_cyclotomic (n : ℕ) (R : Type*) [ring R] [nontrivial R] :
  (cyclotomic n R).nat_degree = nat.totient n :=
by rw [nat_degree, degree_cyclotomic, with_bot.unbot'_coe]

/-- The degree of `cyclotomic n R` is positive. -/
lemma degree_cyclotomic_pos (n : ℕ) (R : Type*) (hpos : 0 < n) [ring R] [nontrivial R] :
  0 < (cyclotomic n R).degree := by
{ rw degree_cyclotomic n R, exact_mod_cast (nat.totient_pos hpos) }

open finset

/-- `∏ i in nat.divisors n, cyclotomic i R = X ^ n - 1`. -/
lemma prod_cyclotomic_eq_X_pow_sub_one {n : ℕ} (hpos : 0 < n) (R : Type*) [comm_ring R] :
  ∏ i in nat.divisors n, cyclotomic i R = X ^ n - 1 :=
begin
  have integer : ∏ i in nat.divisors n, cyclotomic i ℤ = X ^ n - 1,
  { apply map_injective (int.cast_ring_hom ℂ) int.cast_injective,
    simp only [polynomial.map_prod, int_cyclotomic_spec, polynomial.map_pow, map_X,
               polynomial.map_one, polynomial.map_sub],
    exact prod_cyclotomic'_eq_X_pow_sub_one hpos (complex.is_primitive_root_exp n hpos.ne') },
  simpa only [polynomial.map_prod, map_cyclotomic_int, polynomial.map_sub, polynomial.map_one,
    polynomial.map_pow, polynomial.map_X] using congr_arg (map (int.cast_ring_hom R)) integer
end

lemma cyclotomic.dvd_X_pow_sub_one (n : ℕ) (R : Type*) [ring R] :
  (cyclotomic n R) ∣ X ^ n - 1 :=
begin
  suffices : cyclotomic n ℤ ∣ X ^ n - 1,
  { simpa only [map_cyclotomic_int, polynomial.map_sub, polynomial.map_one, polynomial.map_pow,
      polynomial.map_X] using map_dvd (int.cast_ring_hom R) this },
  rcases n.eq_zero_or_pos with rfl | hn,
  { simp },
  rw [← prod_cyclotomic_eq_X_pow_sub_one hn],
  exact finset.dvd_prod_of_mem _ (n.mem_divisors_self hn.ne')
end

lemma prod_cyclotomic_eq_geom_sum {n : ℕ} (h : 0 < n) (R) [comm_ring R] :
  ∏ i in n.divisors.erase 1, cyclotomic i R = ∑ i in finset.range n, X ^ i :=
suffices ∏ i in n.divisors.erase 1, cyclotomic i ℤ = ∑ i in finset.range n, X ^ i,
by simpa only [polynomial.map_prod, map_cyclotomic_int, polynomial.map_sum, polynomial.map_pow,
  polynomial.map_X] using congr_arg (map (int.cast_ring_hom R)) this,
by rw [← mul_left_inj' (cyclotomic_ne_zero 1 ℤ), prod_erase_mul _ _ (nat.one_mem_divisors.2 h.ne'),
  cyclotomic_one, geom_sum_mul, prod_cyclotomic_eq_X_pow_sub_one h]

/-- If `p` is prime, then `cyclotomic p R = ∑ i in range p, X ^ i`. -/
lemma cyclotomic_prime (R : Type*) [ring R] (p : ℕ) [hp : fact p.prime] :
  cyclotomic p R = ∑ i in finset.range p, X ^ i :=
begin
  suffices : cyclotomic p ℤ = ∑ i in range p, X ^ i,
  { simpa only [map_cyclotomic_int, polynomial.map_sum, polynomial.map_pow, polynomial.map_X]
      using congr_arg (map (int.cast_ring_hom R)) this },
  rw [← prod_cyclotomic_eq_geom_sum hp.out.pos, hp.out.divisors,
    erase_insert (mem_singleton.not.2 hp.out.ne_one.symm), prod_singleton]
end

lemma cyclotomic_prime_mul_X_sub_one (R : Type*) [ring R] (p : ℕ) [hn : fact (nat.prime p)] :
  (cyclotomic p R) * (X - 1) = X ^ p - 1 :=
by rw [cyclotomic_prime, geom_sum_mul]

@[simp] lemma cyclotomic_two (R : Type*) [ring R] : cyclotomic 2 R = X + 1 :=
by simp [cyclotomic_prime]

@[simp] lemma cyclotomic_three (R : Type*) [ring R] : cyclotomic 3 R = X ^ 2 + X + 1 :=
by simp [cyclotomic_prime, sum_range_succ']

lemma cyclotomic_dvd_geom_sum_of_dvd (R) [ring R] {d n : ℕ} (hdn : d ∣ n)
  (hd : d ≠ 1) : cyclotomic d R ∣ ∑ i in finset.range n, X ^ i :=
begin
  suffices : cyclotomic d ℤ ∣ ∑ i in finset.range n, X ^ i,
  { simpa only [map_cyclotomic_int, polynomial.map_sum, polynomial.map_pow, polynomial.map_X]
      using map_dvd (int.cast_ring_hom R) this },
  rcases n.eq_zero_or_pos with rfl | hn,
  { simp },
  rw ←prod_cyclotomic_eq_geom_sum hn,
  apply finset.dvd_prod_of_mem,
  simp [hd, hdn, hn.ne']
end

lemma X_pow_sub_one_mul_prod_cyclotomic_eq_X_pow_sub_one_of_dvd (R) [comm_ring R] {d n : ℕ}
  (h : d ∈ n.proper_divisors) :
  (X ^ d - 1) * ∏ x in n.divisors \ d.divisors, cyclotomic x R = X ^ n - 1 :=
begin
  obtain ⟨hd, hdn⟩ := nat.mem_proper_divisors.mp h,
  have h0n : 0 < n := pos_of_gt hdn,
  have h0d : 0 < d := nat.pos_of_dvd_of_pos hd h0n,
  rw [←prod_cyclotomic_eq_X_pow_sub_one h0d, ←prod_cyclotomic_eq_X_pow_sub_one h0n,
      mul_comm, finset.prod_sdiff (nat.divisors_subset_of_dvd h0n.ne' hd)]
end

lemma X_pow_sub_one_mul_cyclotomic_dvd_X_pow_sub_one_of_dvd (R) [comm_ring R] {d n : ℕ}
  (h : d ∈ n.proper_divisors) : (X ^ d - 1) * cyclotomic n R ∣ X ^ n - 1 :=
begin
  have hdn := (nat.mem_proper_divisors.mp h).2,
  use ∏ x in n.proper_divisors \ d.divisors, cyclotomic x R,
  symmetry,
  convert X_pow_sub_one_mul_prod_cyclotomic_eq_X_pow_sub_one_of_dvd R h using 1,
  rw mul_assoc,
  congr' 1,
  rw [← nat.insert_self_proper_divisors hdn.ne_bot, insert_sdiff_of_not_mem, prod_insert],
  { exact finset.not_mem_sdiff_of_not_mem_left nat.proper_divisors.not_self_mem },
  { exact λ hk, hdn.not_le $ nat.divisor_le hk }
end

section arithmetic_function
open nat.arithmetic_function
open_locale arithmetic_function

/-- `cyclotomic n R` can be expressed as a product in a fraction field of `R[X]`
  using Möbius inversion. -/
lemma cyclotomic_eq_prod_X_pow_sub_one_pow_moebius {n : ℕ} (R : Type*) [comm_ring R] [is_domain R] :
  algebra_map _ (ratfunc R) (cyclotomic n R) =
    ∏ i in n.divisors_antidiagonal, (algebra_map R[X] _ (X ^ i.snd - 1)) ^ μ i.fst :=
begin
  rcases n.eq_zero_or_pos with rfl | hpos,
  { simp },
  have h : ∀ (n : ℕ), 0 < n →
    ∏ i in nat.divisors n, algebra_map _ (ratfunc R) (cyclotomic i R) = algebra_map _ _ (X ^ n - 1),
  { intros n hn,
    rw [← prod_cyclotomic_eq_X_pow_sub_one hn R, ring_hom.map_prod] },
  rw (prod_eq_iff_prod_pow_moebius_eq_of_nonzero (λ n hn, _) (λ n hn, _)).1 h n hpos;
  rw [ne.def, is_fraction_ring.to_map_eq_zero_iff],
  { apply cyclotomic_ne_zero },
  { apply monic.ne_zero,
    apply monic_X_pow_sub_C _ (ne_of_gt hn) }
end

end arithmetic_function

/-- We have
`cyclotomic n R = (X ^ k - 1) /ₘ (∏ i in nat.proper_divisors k, cyclotomic i K)`. -/
lemma cyclotomic_eq_X_pow_sub_one_div {R : Type*} [comm_ring R] {n : ℕ}
  (hpos: 0 < n) : cyclotomic n R = (X ^ n - 1) /ₘ (∏ i in nat.proper_divisors n, cyclotomic i R) :=
begin
  nontriviality R,
  rw [←prod_cyclotomic_eq_X_pow_sub_one hpos, ← nat.cons_self_proper_divisors hpos.ne',
    finset.prod_cons],
  have prod_monic : (∏ i in nat.proper_divisors n, cyclotomic i R).monic,
  { apply monic_prod_of_monic,
    intros i hi,
    exact cyclotomic.monic i R },
  rw (div_mod_by_monic_unique (cyclotomic n R) 0 prod_monic _).1,
  simp only [degree_zero, zero_add],
  split,
  { rw mul_comm },
  rw [bot_lt_iff_ne_bot],
  intro h,
  exact monic.ne_zero prod_monic (degree_eq_bot.1 h)
end

/-- If `m` is a proper divisor of `n`, then `X ^ m - 1` divides
`∏ i in nat.proper_divisors n, cyclotomic i R`. -/
lemma X_pow_sub_one_dvd_prod_cyclotomic (R : Type*) [comm_ring R] {n m : ℕ} (hpos : 0 < n)
  (hm : m ∣ n) (hdiff : m ≠ n) : X ^ m - 1 ∣ ∏ i in nat.proper_divisors n, cyclotomic i R :=
begin
  replace hm := nat.mem_proper_divisors.2 ⟨hm, lt_of_le_of_ne (nat.divisor_le (nat.mem_divisors.2
    ⟨hm, hpos.ne'⟩)) hdiff⟩,
  rw [← finset.sdiff_union_of_subset (nat.divisors_subset_proper_divisors (ne_of_lt hpos).symm
    (nat.mem_proper_divisors.1 hm).1 (ne_of_lt (nat.mem_proper_divisors.1 hm).2)),
    finset.prod_union finset.sdiff_disjoint,
    prod_cyclotomic_eq_X_pow_sub_one (nat.pos_of_mem_proper_divisors hm)],
  exact ⟨(∏ (x : ℕ) in n.proper_divisors \ m.divisors, cyclotomic x R), by rw mul_comm⟩
end

/-- If there is a primitive `n`-th root of unity in `K`, then
`cyclotomic n K = ∏ μ in primitive_roots n R, (X - C μ)`. In particular,
`cyclotomic n K = cyclotomic' n K` -/
lemma cyclotomic_eq_prod_X_sub_primitive_roots {K : Type*} [comm_ring K] [is_domain K] {ζ : K}
  {n : ℕ} (hz : is_primitive_root ζ n) :
  cyclotomic n K = ∏ μ in primitive_roots n K, (X - C μ) :=
begin
  rw ←cyclotomic',
  induction n using nat.strong_induction_on with k hk generalizing ζ hz,
  obtain hzero | hpos := k.eq_zero_or_pos,
  { simp only [hzero, cyclotomic'_zero, cyclotomic_zero] },
  have h : ∀ i ∈ k.proper_divisors, cyclotomic i K = cyclotomic' i K,
  { intros i hi,
    obtain ⟨d, hd⟩ := (nat.mem_proper_divisors.1 hi).1,
    rw mul_comm at hd,
    exact hk i (nat.mem_proper_divisors.1 hi).2 (is_primitive_root.pow hpos hz hd) },
  rw [@cyclotomic_eq_X_pow_sub_one_div _ _ _ hpos,
      cyclotomic'_eq_X_pow_sub_one_div hpos hz, finset.prod_congr (refl k.proper_divisors) h]
end

lemma eq_cyclotomic_iff {R : Type*} [comm_ring R] {n : ℕ} (hpos: 0 < n)
  (P : R[X]) :
  P = cyclotomic n R ↔ P * (∏ i in nat.proper_divisors n, polynomial.cyclotomic i R) = X ^ n - 1 :=
begin
  nontriviality R,
  refine ⟨λ hcycl, _, λ hP, _⟩,
  { rw [hcycl, ← prod_cyclotomic_eq_X_pow_sub_one hpos R, ← nat.cons_self_proper_divisors hpos.ne',
        finset.prod_cons] },
  { have prod_monic : (∏ i in nat.proper_divisors n, cyclotomic i R).monic,
    { apply monic_prod_of_monic,
      intros i hi,
      exact cyclotomic.monic i R },
    rw [@cyclotomic_eq_X_pow_sub_one_div R _ _ hpos,
      (div_mod_by_monic_unique P 0 prod_monic _).1],
    refine ⟨by rwa [zero_add, mul_comm], _⟩,
    rw [degree_zero, bot_lt_iff_ne_bot],
    intro h,
    exact monic.ne_zero prod_monic (degree_eq_bot.1 h) },
end

/-- If `p ^ k` is a prime power, then
`cyclotomic (p ^ (n + 1)) R = ∑ i in range p, (X ^ (p ^ n)) ^ i`. -/
lemma cyclotomic_prime_pow_eq_geom_sum {R : Type*} [comm_ring R] {p n : ℕ} (hp : p.prime) :
  cyclotomic (p ^ (n + 1)) R = ∑ i in finset.range p, (X ^ (p ^ n)) ^ i :=
begin
  have : ∀ m, cyclotomic (p ^ (m + 1)) R = ∑ i in finset.range p, (X ^ (p ^ m)) ^ i ↔
    (∑ i in finset.range p, (X ^ (p ^ m)) ^ i) * ∏ (x : ℕ) in finset.range (m + 1),
      cyclotomic (p ^ x) R = X ^ p ^ (m + 1) - 1,
  { intro m,
    have := eq_cyclotomic_iff (pow_pos hp.pos (m + 1)) _,
    rw eq_comm at this,
    rw [this, nat.prod_proper_divisors_prime_pow hp], },
  induction n with n_n n_ih,
  { haveI := fact.mk hp, simp [cyclotomic_prime], },
  rw ((eq_cyclotomic_iff (pow_pos hp.pos (n_n.succ + 1)) _).mpr _).symm,
  rw [nat.prod_proper_divisors_prime_pow hp, finset.prod_range_succ, n_ih],
  rw this at n_ih,
  rw [mul_comm _ (∑ i in _, _), n_ih, geom_sum_mul, sub_left_inj, ← pow_mul, pow_add, pow_one],
end

lemma cyclotomic_prime_pow_mul_X_pow_sub_one (R : Type*) [comm_ring R] (p k : ℕ)
  [hn : fact (nat.prime p)] :
  (cyclotomic (p ^ (k + 1)) R) * (X ^ (p ^ k) - 1) = X ^ (p ^ (k + 1)) - 1 :=
by rw [cyclotomic_prime_pow_eq_geom_sum hn.out, geom_sum_mul, ← pow_mul, pow_succ, mul_comm]

/-- The constant term of `cyclotomic n R` is `1` if `2 ≤ n`. -/
lemma cyclotomic_coeff_zero (R : Type*) [comm_ring R] {n : ℕ} (hn : 1 < n) :
  (cyclotomic n R).coeff 0 = 1 :=
begin
  induction n using nat.strong_induction_on with n hi,
  have hprod : (∏ i in nat.proper_divisors n, (polynomial.cyclotomic i R).coeff 0) = -1,
  { rw [←finset.insert_erase (nat.one_mem_proper_divisors_iff_one_lt.2
      (lt_of_lt_of_le one_lt_two hn)), finset.prod_insert (finset.not_mem_erase 1 _),
      cyclotomic_one R],
    have hleq : ∀ j ∈ n.proper_divisors.erase 1, 2 ≤ j,
    { intros j hj,
      apply nat.succ_le_of_lt,
      exact (ne.le_iff_lt ((finset.mem_erase.1 hj).1).symm).mp
              (nat.succ_le_of_lt (nat.pos_of_mem_proper_divisors (finset.mem_erase.1 hj).2)) },
    have hcongr : ∀ j ∈ n.proper_divisors.erase 1, (cyclotomic j R).coeff 0 = 1,
    { intros j hj,
      exact hi j (nat.mem_proper_divisors.1 (finset.mem_erase.1 hj).2).2 (hleq j hj) },
    have hrw : ∏ (x : ℕ) in n.proper_divisors.erase 1, (cyclotomic x R).coeff 0 = 1,
    { rw finset.prod_congr (refl (n.proper_divisors.erase 1)) hcongr,
      simp only [finset.prod_const_one] },
    simp only [hrw, mul_one, zero_sub, coeff_one_zero, coeff_X_zero, coeff_sub] },
  have heq : (X ^ n - 1).coeff 0 = -(cyclotomic n R).coeff 0,
  { rw [← prod_cyclotomic_eq_X_pow_sub_one (zero_le_one.trans_lt hn),
        ← nat.cons_self_proper_divisors hn.ne_bot, finset.prod_cons, mul_coeff_zero,
        coeff_zero_prod, hprod, mul_neg, mul_one] },
  have hzero : (X ^ n - 1).coeff 0 = (-1 : R),
  { rw coeff_zero_eq_eval_zero _,
    simp only [zero_pow (lt_of_lt_of_le zero_lt_two hn), eval_X, eval_one, zero_sub, eval_pow,
              eval_sub] },
  rw hzero at heq,
  exact neg_inj.mp (eq.symm heq)
end

/-- If `(a : ℕ)` is a root of `cyclotomic n (zmod p)`, where `p` is a prime, then `a` and `p` are
coprime. -/
lemma coprime_of_root_cyclotomic {n : ℕ} (hpos : 0 < n) {p : ℕ} [hprime : fact p.prime] {a : ℕ}
  (hroot : is_root (cyclotomic n (zmod p)) (nat.cast_ring_hom (zmod p) a)) :
  a.coprime p :=
begin
  apply nat.coprime.symm,
  rw [hprime.1.coprime_iff_not_dvd],
  intro h,
  replace h := (zmod.nat_coe_zmod_eq_zero_iff_dvd a p).2 h,
  rw [is_root.def, eq_nat_cast, h, ← coeff_zero_eq_eval_zero] at hroot,
  by_cases hone : n = 1,
  { simp only [hone, cyclotomic_one, zero_sub, coeff_one_zero, coeff_X_zero, neg_eq_zero,
    one_ne_zero, coeff_sub] at hroot,
    exact hroot },
  rw [cyclotomic_coeff_zero (zmod p) (nat.succ_le_of_lt (lt_of_le_of_ne
        (nat.succ_le_of_lt hpos) (ne.symm hone)))] at hroot,
  exact one_ne_zero hroot
end

end cyclotomic

section order

/-- If `(a : ℕ)` is a root of `cyclotomic n (zmod p)`, then the multiplicative order of `a` modulo
`p` divides `n`. -/
lemma order_of_root_cyclotomic_dvd {n : ℕ} (hpos : 0 < n) {p : ℕ} [fact p.prime]
  {a : ℕ} (hroot : is_root (cyclotomic n (zmod p)) (nat.cast_ring_hom (zmod p) a)) :
  order_of (zmod.unit_of_coprime a (coprime_of_root_cyclotomic hpos hroot)) ∣ n :=
begin
  apply order_of_dvd_of_pow_eq_one,
  suffices hpow : eval (nat.cast_ring_hom (zmod p) a) (X ^ n - 1 : (zmod p)[X]) = 0,
  { simp only [eval_X, eval_one, eval_pow, eval_sub, eq_nat_cast] at hpow,
    apply units.coe_eq_one.1,
    simp only [sub_eq_zero.mp hpow, zmod.coe_unit_of_coprime, units.coe_pow] },
  rw [is_root.def] at hroot,
  rw [← prod_cyclotomic_eq_X_pow_sub_one hpos (zmod p), ← nat.cons_self_proper_divisors hpos.ne',
    finset.prod_cons, eval_mul, hroot, zero_mul]
end

end order

end polynomial
