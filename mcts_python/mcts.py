import random
import math
from copy import deepcopy
import numpy as np

class MCTS():

  def __init__(self, exploration_rate, anet):
    self.c = exploration_rate
    self.anet = anet

  def uct_search(self, tree, node, M):
    """
    The main MCTS algorithm. Runs M simulations to create the tree.
    Then selects the best child state for the given input state
    """
    game = deepcopy(node.game)
    for i in range(M):
      self.simulate(tree, node)

    best_child = self.tree_policy(node)
    node.game = game

    return best_child


  def tree_policy(self, node):
    visits = [child.visits for child in node.children]
    return node.children[np.argmax(visits)]

  def simulate(self, tree, node):
    """
    The general simulation algorithm, tree traversal, rollout and backprop.
    """
    selected_node = self.sim_tree(tree, node)
    z = self.sim_default(tree, selected_node.game)
    self.backup(selected_node, z)

  def sim_tree(self, tree, node):
    """
    Traversing the tree from the root to a leaf node by using the tree policy.
    """
    c = self.c
    game = deepcopy(node.game)
    while (not game.is_finished()):
      if not node in tree.nodes:
        self.new_node(tree, node)
        return node

      node = self.select_best_child(node, c)
      game.execute_move(node.move)
    return node

  def new_node(self, tree, node):
    """
    Generating some or all child states of a parent state, and then connecting
    the tree node housing the parent state (a.k.a. parent node) to the nodes
    housing the child states (a.k.a. child nodes).
    """
    tree.nodes.append(node)
    node.Q = 0
    node.visits = 0
    for a in node.game.get_moves():
      game = deepcopy(node.game)
      game.execute_move(a)
      child_node = tree.create_node(game, node, a)
      node.children.append(child_node)

  def sim_default(self,tree, game):
    """
    Estimating the value of a leaf node in the tree by doing a rollout
    simulation using the default policy from the leaf node’s state to a
    final state.
    """
    def default_policy(game):
      player = game.get_current_player()
      state = np.array([np.concatenate((player,game.board), axis=None)])
      predictions = self.anet.predict(state)[0]
      legal_moves = game.get_moves()
      best_move = self.choose_best_move(predictions, legal_moves)
      return best_move
      
    def random_policy(game):
      moves = game.get_moves()
      return random.choice(moves)

    game = deepcopy(game)
    game.verbose = False
    while (not game.is_finished()):
      if tree.chanceOfRandom > random.random():
        a = random_policy(game)
      else:
        a = default_policy(game)
      game.execute_move(a)
    return game.get_result()

  def choose_best_move(self,predictions, legal_moves):
    best_move = None
    best_score = -1000
    for move in legal_moves:
      score = predictions[move]
      if score > best_score:
        best_move = move
        best_score = score
    return best_move

  def backup(self, selected_node, result):
    """
    Passing the evaluation of a final state back up the tree, updating
    relevant data (see course lecture notes) at all nodes and edges on
    the path from the final state to the tree root.
    """
    node = selected_node
    while node != None:
      node.visits += 1
      node.Q += (result - node.Q) / node.visits
      node = node.parent

  def select_best_child(self, node, c):
    """
    Selects the best child of a given state, based on the node visits
    and scores (Q-values).
    """
    game = node.game
    current_player = game.get_current_player()
    positive = current_player == game.start_player
    children = node.children
    child_scores = []
    for child in children:
      uct = c * math.sqrt(math.log(node.visits) / (child.visits + 1))
      score = child.Q + uct if positive else child.Q - uct
      child_scores.append(score)

    if (positive):
      best_child_index = np.argmax(child_scores)
    else:
      best_child_index = np.argmin(child_scores)
    
    return children[best_child_index]
