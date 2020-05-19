import numpy as np
from disjoint_set import DisjointSet
import math
import random
import matplotlib.pyplot as plt
from copy import deepcopy, copy


class Hex():
    def __init__(self, boardsize):
        self.boardsize = boardsize
        self.board = np.zeros(boardsize**2)
        self.start_player = 1
        self.legal_moves = [-1, 1, -boardsize, boardsize, -(boardsize-1), boardsize-1]
        self.executedMoves = []
        self.disjoint_set1 = DisjointSet()
        self.disjoint_set2 = DisjointSet()


    def get_moves(self):
        return np.where(self.board == 0)[0]

    def get_current_player(self):
        if (len(self.executedMoves) % 2) == 0:
            return self.start_player
        else:
            return self.opposite_player(self.start_player)
    
    def opposite_player(self, player):
        return 2 if player == 1 else 1
    
    def get_winner(self):
        if (len(self.executedMoves) % 2) == 0:
            return self.opposite_player(self.start_player)
        else:
            return self.start_player

    def get_result(self):
        winner = self.get_winner()
        if self.is_finished():
            if self.start_player == winner:
                return 1
            else:
                return -1
        print("The game is not finished, somethings wrong")
            
    def get_neighbors(self, position, player):
        neighbors = set()
        for move in self.legal_moves:
            if self.check_bounds(position, move):
                    value = self.get_edge(position, move, player)
                    if value != None:
                        neighbors.add(value)  
                    continue
            if (position + move) < 0 and player == 1:
                value = self.get_edge(position, move, player)
                neighbors.add(value)
                continue
            try:
                if self.has_neighbor(position, move, player) and position + move >= 0:
                    neighbors.add(position + move)
            except IndexError:
                value = self.get_edge(position, move, player)
                if value != None:
                    neighbors.add(value)
        return neighbors


    def has_neighbor(self, position, move, player):
        return self.board[position + move] == player

    def check_bounds(self, position, move):
        diff = abs(((position + move) % self.boardsize) - position % self.boardsize) < 2 
        return not diff

    def get_edge(self, position, move, player):
        if (position + move) < 0 and player == 1: 
            return self.boardsize**2 + 1
        if position + move > self.boardsize**2 - 1 and player == 1:
            return self.boardsize**2 + 2
        if self.leftedge(position, move) and player == 2:
            return self.boardsize**2 + 3
        if self.rightedge(position, move) and player == 2:
            return self.boardsize**2 + 4
        else:
            return None
        
    def leftedge(self, position, move):
        diff = (((position + move) % self.boardsize) - position % self.boardsize)
        return not diff < 2

    def rightedge(self, position, move):
        diff = (((position + move) % self.boardsize) - position % self.boardsize)
        return not diff > -2 

    def execute_move(self, move):
        player = self.get_current_player()
        neighbors = self.get_neighbors(move, player)
        ds = self.disjoint_set1 if player == 1 else self.disjoint_set2
        for neighbor in neighbors:
            ds.union(neighbor, move)
        self.executedMoves.append(move)
        np.put(self.board,move,player)


    def is_finished(self):
        if self.disjoint_set1.connected((self.boardsize**2 + 1), (self.boardsize**2 + 2)):
            return True
        if self.disjoint_set2.connected((self.boardsize**2 + 3), (self.boardsize**2 + 4)):
            return True
        else:
            return False
    
    def __deepcopy__(self, memo):
        new = Hex(self.boardsize)
        for move in self.executedMoves:
            new.execute_move(move)
        return new

    def test_play(self):
        while not self.is_finished():
            possibleMoves = self.get_moves()
            if len(possibleMoves) == 0:
                print(self.board)
                print(np.reshape(self.board, (4,4)))
                print(self.executedMoves)
                print(self.disjoint_set1)
                print(self.disjoint_set2)
            move = random.choice(possibleMoves)
            print("Move: ", move)
            self.execute_move(move)
        winner = self.get_winner()
        print("Finished: ", self.is_finished())
        print("The winner is {}".format(winner))
        print(self.disjoint_set1)
        print(self.disjoint_set2)


#hex = Hex(4)
a = [0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15]
"""
for i in a:
    k = hex.get_neighbors(i, 2)
    print("position: {}, neighbors: {}".format(i,k))
"""

#moves = [5, 14, 13, 3, 7, 8, 6, 2, 4, 11, 10, 0, 9, 12, 15, 1]
"""
for move in moves:
    hex.execute_move(move)

#hex.test_play()
#print(hex.board)
print(hex.check_bounds(1,-1))
print(np.reshape(hex.board, (4,4)))
print(hex.is_finished())
print(hex.disjoint_set1)
print(hex.disjoint_set2)
#plt.matshow(np.reshape(hex.board,(4,4)))
"""




