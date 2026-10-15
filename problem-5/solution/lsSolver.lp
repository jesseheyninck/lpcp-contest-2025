#const m=3.

%input(1,1,1). input(1,2,2). input(1,3,3). input(1,4,4). input(2,1,2). input(2,4,3). input(3,4,2). input(4,3,2). input(4,4,1). input(2,2,4). input(2,3,1). input(3,1,3). input(3,2,1). input(3,3,4). input(4,1,4). input(4,2,3).
input(1,1,1).
{fill(X,Y,M): M=1..m}=1:- not input(X,Y,_), X=1..m, Y=1..m.

ls(X,Y,M):- fill(X,Y,M).
ls(X,Y,M):- input(X,Y,M).

:- ls(X1,Y,M), ls(X2,Y,M), X1!=X2.
:- ls(X,Y1,M), ls(X,Y2,M), Y1!=Y2.

#show fill/3.