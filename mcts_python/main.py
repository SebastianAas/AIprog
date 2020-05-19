import random
from config import *
from state_manager import StateManager
from mcts import MCTS
import pandas as pd
from tree import Tree
from utils import Timer
import numpy as np
from utils import normalize
from anet import ANET
import collections

def progress_bar(current_game):
  percentage = int((current_game / num_of_games)*100)
  print("Episode: {}/{} {}%".format(current_game, num_of_games, percentage))

def train_anet(anet, RBUF):
  # Creates a minibatch of the RBUF and trains the anet on the minibatch
  batch_size = min(32, len(RBUF))
  minibatch = random.sample(RBUF, k=batch_size)
  x_train, y_train = zip(*minibatch)
  anet.train(np.asarray(x_train), np.asarray(y_train))

def get_distribution(node):
  distribution = np.zeros(node.game.boardsize**2) 
  for child in node.children:
    distribution[child.move] = child.visits
  print(distribution)
  D = normalize(distribution)
  return D



""" Initializations """
anet = ANET(boardsize)
agent = MCTS(exploration_rate=1, anet=anet)
sm = StateManager(boardsize)
game = sm.create_game()
tree = Tree(game, 1.0)
win_stats = []


# TODO: Save interval for ANET parameters
RBUF = collections.deque(maxlen=500)

for i in range(1,num_of_games+1):
  progress_bar(i+1)
  state = tree.root

  while (not sm.is_finished()):
    player = sm.game.get_current_player()
    best_child = agent.uct_search(tree, state, num_search_games)
    distribution = get_distribution(best_child.parent)
    RBUF.append((np.concatenate((player, best_child.game.board),axis=None), distribution))
    x_train, y_train = zip(*RBUF)
    print("Move: ", best_child.move)
    game.execute_move(best_child.move)
    state = best_child

  # Train ANET on a random minibatch from RBUF
  train_anet(anet, RBUF)

  if i % save_interval == 0:
    anet.model.save('./trainedModels/model-{}.h5'.format(i))

  win_stats.append(game.get_winner())
  print("Player {} won the game!".format(game.get_winner()))

  game = sm.create_game()
  tree = Tree(game, tree.chanceOfRandom * 0.97)

x_train, y_train = zip(*RBUF)
np.save("train1.npy", np.asarray(x_train))
np.save("labels1.npy", np.asarray(y_train))
player1_wins = win_stats.count(1)
percentage = int((player1_wins / num_of_games) * 100)
print("Player 1 won {} of {} games ({}%)".format(player1_wins, num_of_games, percentage))
