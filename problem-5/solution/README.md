# Problem 5 – Bureaucratic Latin Square: solution

Given a complete Latin square `L` of order `N`, find a smallest set of clues
(cells left visible) such that `L` is the **only** Latin square that agrees
with those clues. In the literature this is a *smallest defining set* of `L`.

`solution.lp` solves this in one call to clingo using a **disjunctive
program with saturation**.

## Files

| File | Purpose |
|---|---|
| `solution.lp` | The ASP encoding (guess + saturation check + optimisation). |
| `lsSolver.lp` | Small helper: completes a partial Latin square; handy for manually checking that a clue set has exactly one completion. |
| `../input.py` | Converts an instance into facts `#const m=N.` and `input(Row,Col,Val).` |
| `../output.py` | Converts `output(Row,Col,Val)` atoms back to the grid format. |

## Running

From `problem-5/`:

```bash
python3 input.py < instance.0.in | clingo - solution/solution.lp --time-limit=55 --outf=0 -V0 --quiet=1 | python3 output.py
```

* `-` makes clingo read the facts from the pipe.
* `--time-limit=55` makes clingo stop on its own and still print the best
  model found so far (an external `kill` would lose it).
* `--outf=0 -V0 --quiet=1` prints only the last (best) model, which is what
  `output.py` parses.

> **Note:** the `output/3` rules in `solution.lp` are currently commented
> out, so `output.py` prints nothing until they are enabled. The clues can
> be read off the `blank/2` atoms meanwhile: every cell that is *not* blank is
> a clue.

## Why this problem needs saturation

The problem has two levels of quantification:

> **exists** a set of clues `C` such that
> **for all** Latin squares `L'` agreeing with `C`: `L' = L`.

The inner "for all" is a co-NP check (uniqueness of completion), so deciding
whether a clue set of size `k` exists is in Σ₂ᴾ. Normal ASP programs (and
choice rules) can only express problems in NP, since an answer set just
*guesses* something and checks it. Expressing a universal check needs
**disjunctive** ASP, whose minimality semantics provides the second level.
The standard way to use it for a universal check is the **saturation
technique**, which goes back to Eiter & Gottlob's Σ₂ᴾ-hardness proof for
disjunctive ASP (1995).

### The idea in one paragraph

Answer sets of a disjunctive program are **minimal** models (of the reduct).
Saturation exploits this:

1. A disjunctive rule guesses a *candidate counterexample* (here: an
   alternative filling of the blanks).
2. If the candidate is **not** a real counterexample, the special atom `bad`
   is derived.
3. Whenever `bad` holds, rules **saturate** the model: they make *every*
   guess atom true. All candidates therefore collapse into one and the same
   maximal interpretation `I_sat`.
4. The constraint `:- not bad.` throws away every interpretation without `bad`.

Now, `I_sat` is an answer set **iff** it is a *minimal* model. If some
candidate is a genuine counterexample (no `bad` derived), it forms a smaller
model strictly inside `I_sat`, so `I_sat` is not minimal and there is no
answer set. Hence:

> `I_sat` is an answer set ⟺ **every** candidate leads to `bad`
> ⟺ there is no counterexample.

Rather than enumerating counterexamples one by one, the solver compares models
under set inclusion, and that comparison carries out the universal check.

## The encoding, piece by piece

### 1. Outer guess: which cells to redact

```prolog
{blank(Y,X)}:- input(Y,X,N).
numberOfBlanks(Z):- #count{Y,X: blank(Y,X)}=Z.
#minimize{-N: numberOfBlanks(N)}.
```

Choose a set of blanks and maximise their number (equivalently, minimise
the number of clues). This part is ordinary choice-rule ASP. It is the
"exists" level, and saturation never touches these atoms.

### 2. Inner guess: a candidate alternative square

```prolog
bad(Y,X),alternative(Y,X,M): M=1..m, M!=N:- blank(Y,X), input(Y,X,N).
```

For every blank cell, the disjunction picks **either**

* `alternative(Y,X,M)` with `M ≠` the original value: the cell *changes*,
  **or**
* `bad(Y,X)`: the cell *keeps* its original value.

```prolog
filled(Y,X,M):- input(Y,X,M), not blank(Y,X).   % clues
filled(Y,X,M):- input(Y,X,M),  bad(Y,X).        % unchanged blanks
filled(Y,X,M):- blank(Y,X), alternative(Y,X,M). % changed blanks
```

So `filled/3` is the candidate square `L'`. Every possible `L'` that agrees
with the clues is one choice in the disjunction: change the blanks where
`L'` differs from `L`, keep the rest.

(`not blank(Y,X)` is harmless here: `blank/2` belongs to the outer guess, so
it is fixed by the time the reduct is taken, and negation is never applied to
the saturated atoms themselves.)

### 3. Recognising "not a counterexample"

`L'` fails as a counterexample if it is **not Latin** or if it is
**identical to `L`**.

```prolog
bad(Y,X1):-  filled(Y,X1,M), filled(Y,X2,M), X1!=X2.   % row clash
bad(Y1,X):- filled(Y1,X,M), filled(Y2,X,M), Y1!=Y2.   % column clash
bad:- bad(X,Y):blank(X,Y).                             % all blanks "unchanged"
```

A clash marks the clashing cells as `bad(Y,X)`, which by the `filled` rule
gives them their original value. That can trigger further clashes, and so on.
The global `bad` holds exactly when every blank ends up marked `bad(Y,X)`.
At that point the candidate either coincides with `L` or has been shown
inconsistent.

### 4. Saturation and the final check

```prolog
alternative(Y1,X1,M):-bad, input(Y1,X1,N), blank(Y1,X1), M=1..m, M!=N.
:- not bad.
```

Once `bad` is derived, *every* `alternative` atom becomes true. With them
every `filled` value appears, so every cell clashes and every `bad(Y,X)` is
derived too. The result is the single saturated interpretation `I_sat`, and
`:- not bad.` keeps only that one.

## Why it is correct

Fix the outer guess (a set of blanks). For the inner part we need:
`I_sat` is a minimal model ⟺ `L` is the unique completion.

* **If another completion `L' ≠ L` exists:** take `alternative(c, L'(c))`
  for the blanks where `L'` differs from `L`, `bad(c)` for the others, and
  the derived `filled` atoms. Because `L'` is Latin, no clash is derived. At
  least one blank differs, so not every blank is `bad(c)`, and therefore
  `bad` is not derived. This is a model strictly inside `I_sat`, so `I_sat`
  is not minimal. The clue set is **rejected**.

* **If `L` is the unique completion:** take a model `J ⊊ I_sat` without
  `bad`. Some blank `c` lacks `bad(c)`, so it carries an alternative value.
  Such a cell takes part in no row or column clash, since a clash would have
  derived `bad(c)`. Build `L'` from the original values on clues and
  `bad`-cells, plus one alternative value on each remaining blank. The
  original values never clash among themselves, and the changed cells clash
  with nothing, so `L'` is a Latin square different from `L`. That
  contradicts uniqueness. So `I_sat` is minimal and the clue set is
  **accepted**.

The `#minimize` then picks the accepted clue set with the fewest clues.

## Results on the provided instances

The table below comes from running the encoding with `--time-limit=60` and
checking each answer independently: fix the clues, enumerate all Latin
completions, and require exactly one completion, equal to the input.

| Instance | N | Time | Status | Clues | Completions |
|---|---|---|---|---|---|
| 0 | 4 | 0.6 s | optimum proven | 4 | 1 |
| 1 | 4 | 0.5 s | optimum proven | 4 | 1 |
| 2 | 4 | 0.6 s | optimum proven | 4 | 1 |
| 3 | 4 | 0.6 s | optimum proven | 5 | 1 |
| 4 | 4 | 0.5 s | optimum proven | 5 | 1 |
| 5 | 5 | 60 s (limit) | best found, not proven | 7 | 1 |

For comparison, the smallest *critical set* over all Latin squares of order
`n` is conjectured to be ⌊n²/4⌋. That value is 4 for n = 4 and 6 for
n = 5, and the conjecture is known to hold for n ≤ 8. Individual squares can
need more, as instances 3–5 show.

## Possible improvements

Saturation does the uniqueness check in one call, but the search space grows
quickly, and instance 5 already hits the time limit. Possible additions:

* **Latin trades as redundant constraints.** If you take two rows, the
  columns split into cycles (row 2's value at column `c` appears in row 1 at
  column `c'`). Swapping the two rows along one cycle gives another Latin
  square, so every such cycle must contain a clue. The same holds for pairs of
  columns and pairs of symbols. These constraints are sound and prune the
  outer guess heavily. Special cases are "every 2×2 sub-square (intercalate)
  needs a clue" and "at most one row, column or symbol without clues".
* Restricting `alternative/3` to values that do not clash with a clue in
  the same row or column.

## References

* T. Eiter, G. Gottlob. *On the computational cost of disjunctive logic
  programming: Propositional case.* Annals of Mathematics and AI, 1995. This
  is the origin of the saturation technique.
* T. Eiter, G. Ianni, T. Krennwallner. *Answer Set Programming: A Primer.*
  Reasoning Web 2009. Section on saturation / guess-and-check.
* [Solving stable matching problems using answer set programming](https://arxiv.org/pdf/1512.05247)
  is an example of saturation used as a modelling technique, and discusses
  why negation must not touch the saturated atoms.
* [Teaching dimension, VC dimension and critical sets for Latin squares](https://ar5iv.labs.arxiv.org/html/1606.00032)
  covers the ⌊n²/4⌋ bound and conjecture.
* [On the distances between Latin squares and the smallest defining set size](https://ar5iv.labs.arxiv.org/html/1602.07734)
  covers smallest defining sets.
