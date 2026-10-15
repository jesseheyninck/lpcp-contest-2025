
{blank(Y,X)}:- input(Y,X,N).
numberOfBlanks(Z):- #count{Y,X: blank(Y,X)}=Z.



% Disjunction: we make an alternative true or we term the blank "bad"
bad(Y,X),alternative(Y,X,M): M=1..m, M!=N:- blank(Y,X), input(Y,X,N).

% If we derive a blank is bad, we make logical explosion for that blank
alternative(Y1,X1,M):-bad, input(Y1,X1,N), blank(Y1,X1), M=1..m, M!=N.
bad:- bad(X,Y):blank(X,Y).


% If we don't derive bad, latin square conditions should be satisfied.
filled(Y,X,M):- input(Y,X,M), not blank(Y,X).
filled(Y,X,M):- input(Y,X,M),  bad(Y,X).
filled(Y,X,M):- blank(Y,X), alternative(Y,X,M).

%Latin Square conditions
bad(Y,X1):-  filled(Y,X1,M), filled(Y,X2,M), X1!=X2.
bad(Y1,X):- filled(Y1,X,M), filled(Y2,X,M), Y1!=Y2.


%We require logical explosion to be derived. 
:- not bad.
%output(Y,X,0):- blank(Y,X).
%output(Y,X,M):- not blank(Y,X), input(Y,X,M). 
#minimize{-N: numberOfBlanks(N)}.



#show output/3.
#show alternative/3.
#show bad/2.
#show blank/2.
#show filled/3.
#show filled1/3.
#show filled2/3.
#show bad/0.
#show bad1/2.
