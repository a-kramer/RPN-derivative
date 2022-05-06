# Alternatives

Here are some alternative ways to get similar results:

## maxima

```sh
$ echo "display2d:false$ diff(exp(x^2*k),x,1);" | maxima --very-quiet | tail -n1
2*k*x*%e^(k*x^2)
```

## SymPy

[www.sympy.org](https://www.sympy.org/en/index.html)

