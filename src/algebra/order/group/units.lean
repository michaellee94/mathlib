/-
Copyright (c) 2016 Jeremy Avigad. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Jeremy Avigad, Leonardo de Moura, Mario Carneiro, Johannes Hölzl
-/
import algebra.order.group.basic
import algebra.order.monoid.units

/-!
# Adjoining a top element to a `linear_ordered_add_comm_group_with_top`.
-/

variable {α : Type*}

/-- The units of an ordered commutative monoid form an ordered commutative group. -/
@[to_additive "The units of an ordered commutative additive monoid form an ordered commutative
additive group."]
instance units.ordered_comm_group [ordered_comm_monoid α] : ordered_comm_group αˣ :=
{ mul_le_mul_left := λ a b h c, (mul_le_mul_left' (h : (a : α) ≤ b) _ :  (c : α) * a ≤ c * b),
  .. units.partial_order,
  .. units.comm_group }