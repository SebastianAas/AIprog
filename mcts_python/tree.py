from copy import deepcopy

class Node():

  def __init__(self, game, parent=None, move=None):
    """
    A class representing a node in the MCTS tree.
    """
    self.parent = parent
    self.game = game
    self.move = move
    self.Q = 0
    self.visits = 0
    self.children = []

  def __repr__(self):
    return str(self.game)

  def print_info(self):
    print("Node:", self.move)
    print("\tParent:", self.parent)
    print("\tScore:", self.Q)
    print("\tVisits:", self.visits)
    print("\tChildren:", self.children)

class Tree():

  def __init__(self, game, chanceOfRandom):
    self.root = self.create_node(game)
    self.nodes = []
    self.chanceOfRandom = chanceOfRandom

  def create_node(self, game, parent=None, move=None):
    return Node(game=game, parent=parent, move=move)
