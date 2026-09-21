(import (mpl rnrs-sans)
        (mpl all))

(vars a b c d x y z pi t)

(+ x x)
(* x y x)
(+ x y x z 5 z)
(algebraic-expand (alge "(x+1)^2"))
(algebraic-expand (alge "(x+2)*(x+3)*(x+4)"))
(derivative (alge "sin(x)") x)
(derivative (alge "x^3 + 3*x^2 + 5") x)
