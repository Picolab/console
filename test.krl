a = [5, 6, 7];
b = {"x" : 40};
f = function(x){x * x};
x = <<
This is a test
>>;
c = a.map(f)
     .filter(function(x){x < b{"x"}});
{
  "c" : c,
  "a" : a,
  "b" : b,
  "x" : x
}
