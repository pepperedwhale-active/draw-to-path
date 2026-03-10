import sys
import itertools
from sage.all import *
from sage.interfaces.macaulay2 import macaulay2 as m2
from datetime import datetime
from sage.graphs.graph_input import from_dict_of_lists


os.makedirs(f'{sys.argv[1]}')


varlist = [f'a{k}' for k in range(0,100)] 
m2(f'R = QQ[{','.join(varlist)}]') #initialising a polynomial ring in 100 variables a0,a1,...,a99. should be enough variables
m2('use R')
m2('needsPackage "SymbolicPowers"')
m2('needsPackage "GeometricDecomposability"')

def relabel_sage_graph(G): #vertex sets in sage graphs are numbers, which are not allowed to be variables in m2 ideals. so we convert vertex k to the variable ak using this function
    G.relabel({v : f'a{v}' for v in G.vertices()})

def rconnected_ideal(r,G): #computing the r-connected ideal of a graph and returning m2 input
    gens = []
    rtuples = itertools.combinations(G.vertices(),r)
    for x in rtuples:
        S = G.subgraph(x)
        if S.is_connected():
            gens.append('*'.join(str(i) for i in x))
    return f'ideal ({','.join(gens)})'

#to handle a graph you want to enter manually, enter it in the format shown below:

CETOCONJCHECK = {
    1:[10,2,3],
    2:[1,3],
    3:[1,2],
    4:[5,6,11],
    6:[4],
    5:[4],
    7:[12,8],
    8:[7,9],
    9:[8],
    10:[1,11],
    11:[10,12],
    12:[11,7]
}


def nthsymbolic_ordinary_equality(n,I): #checking equality
    m2(f'I = {I}')
    m2(f'J = symbolicPower(I,{n})')
    return 'true' == str(m2(f'J == I^{n}'))



#the following function takes as parameters a set of graphs "family", an index "m" and a number "r". 
#it loops through all members of the family, checks if the m-th symbolic and ordinary powers of their r-connected ideals match.
#then it saves an image of graphs with equality on your system


def checker(graph_family,m,r): 
    print(f"checking equality of {m}-rd(th) symbolic and ordinary powers of {r}-connected ideal(s) of graph(s) in {graph_family}") 
    for G in enumerate(graph_family): 
        relabel_sage_graph(G[1])
        I = rconnected_ideal(r,G[1])
        if nthsymbolic_ordinary_equality(m, I) == True:
            print(G[0])
            print("equality. adjacency matrix of graph:")
            print(G[1].adjacency_matrix()) #printing graph
            plotGraph(G[1], f"{G[0]}.png")
        else:
            print(G[0])
            print("not equal")

def plotGraph(G,name_without_file_extension):
    P = G.plot()
    P.save(f"{sys.argv[1]}/{name_without_file_extension}.png")

def unmixedImpliesCM(graph_family, r):
    for G in enumerate(graph_family):
        relabel_sage_graph(G[1])
        try:
            I = rconnected_ideal(r, G[1])
            m2(f'I = {I}')
            if ('false' == str(m2('isUnmixed I'))):
                print(f"graph {G[0]} is not unmixed")
                continue
            else:
                m2('S = R/I')
                if ('true' == str(m2('depth S == dim S'))):
                    print(f"graph {G[0]} has unmixedness => CMness")
                    plotGraph(G[1], f"unmixedImpliesCM{G[0]}")
                else:
                    print(f"graph {G[0]} has unmixedness but not CMness")
                    plotGraph(G[1], f"unmixedButNotCM{G[0]}")
                m2('use R')
        except:
            print(f"{G[0]} does not have 4path ideal")

def CMImpliesUnmixed(graph_family, r):
    for G in enumerate(graph_family):
        relabel_sage_graph(G[1])
        try:
            I = rconnected_ideal(r,G[1])
            m2(f'I = {I}')
            m2(f'S = R/I')
            if('false' == str(m2('depth S == dim S'))):
                m2('use R')
                print(f"{G[0]} is not CM")
            else:
                m2('use R')
                if ('true' == str(m2('isUnmixed I'))):
                    print(f"{G[0]} has CMness => unmixedness")
                    plotGraph(G[1], f"CMImpliesUnmixed{G[0]}")
                else:
                    plotGraph(G[0], f"CMbutnotUnmixed{G[0]}")
                    print(f"{G[1]} has CMness but not unmixedness")
        except:
            print(f"{G[0]} has no 4connected ideal")

def whisker(G, m):
    WG = Graph(G)
    n = G.num_verts()
    for k, v in enumerate(G.vertices()):
        for i in range(m - 1):
            newvert = n + k * (m - 1) + i
            if i == 0:
                WG.add_edge(v, newvert)
            else:
                WG.add_edge(newvert - 1, newvert)
    return WG

#finding the path ideal given a graph:

def idealise(gens):
    return f"ideal({','.join(gens)})"


def patideal(graph, n):
    def dfs(node, path):
        # If the path has exactly n vertices, add to results
        if len(path) == n:
            result.append(path[:])
            return
        # Explore neighbors
        for neighbor in graph.get(node, []):
            if neighbor not in path:  # Avoid revisiting nodes
                dfs(neighbor, path + [neighbor])

    result = []
    for start_node in graph:  # Try all nodes as starting points
        dfs(start_node, [start_node])
    #converting pathh ideal from list to m2 syntax for ideals
    duplicates = []
    generatorlist = []
    for generator in result:
        if (''.join(sorted(generator))) in duplicates:
            pass
        else:
            generatorlist.append('*'.join(generator))
            duplicates.append(''.join(sorted(generator)))
    
    finalstring = idealise(generatorlist)
    print(finalstring)
    return finalstring

def npathideal(G,n):
    adj_dict = {v: G.neighbors(v) for v in G.vertices()}
    return patideal(adj_dict,n)

#examples. to run any of these, uncomment the code
#below, we check for which connected graphs on 6 vertices the, second symbolic power and the second ordinary power of the 5-connected ideals are equal 
#checker(graphs.nauty_geng("8 -c"), 2, ) 
#here we check if the 2nd sybmolic powers of 4k-cycles of 4-connected ideals work
#checker([graphs.CycleGraph(4*k) for k in range(1,4)],3,4)
#checker([graphs.CycleGraph(4*k) for k in range(1,4)],4,4)
#search found that 4connected ideal, 4th powers of C_12 are not equal.

#unmixedImpliesCM([graphs.CycleGraph(k) for k in range(4,20)], 4)

#unmixedImpliesCM(graphs.nauty_geng("8 -c"),4)
#CMImpliesUnmixed(graphs.nauty_geng("7"),4)

#code for checking the following conjecture on a family of trees: conj: t-connected ideal is CM iff t-path ideal is CM


#k = 4
#for j in range(4,17):
#    for i, T in enumerate(graphs.trees(j)):
#        relabel_sage_graph(T)
#        try:
#            m2('use R')
#            J = npathideal(T, k)
#            m2(f'J = {J}')
#            m2('S = R/J')
#            is_path_CM = str(m2('depth S == dim S')) == 'true'
#
#            if is_path_CM:
#                m2('use R')  # switch back to ring R
#                I = rconnected_ideal(k, T)
#                m2(f'I = {I}')
#                m2('S = R/I')
#                is_conn_CM = str(m2('depth S == dim S')) == 'true'
#
#                if is_conn_CM:
#                    print(f"({i},{j},{k}) is CM for path and connected")
#                    plotGraph(T, f"({i},{j},{k})")
#                else:
#                    print(f"({i},{j},{k}) is CM for path but not connected, counterexample")
#                    plotGraph(T, f"COUNTEREXAMPLE-({i},{j},{k})")
#            else:
#                if (not is_path_CM):
#                    print(f"{i},{j},{k} path ideal is not CM — skipping connected check")
#
#            m2('use R')
#        except Exception as e:
#            print(f"({i},{j},{k}) exception:", e)
#            plotGraph(T, f"ERROR-({i},{j},{k})")


T = graphs.PathGraph(12)
#from_dict_of_lists(T,CETOCONJCHECK)
#print(T.adjacency_matrix()) 
relabel_sage_graph(T)
#plotGraph(T,"uhh")
J = rconnected_ideal(4,T)
#print(f'{J}')
m2(f'J = {J}')
minParams  = str(m2('minimalPrimes(J)'))
print(f'{minParams}')
