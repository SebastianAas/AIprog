import os
import random
import numpy as np
import tensorflow as tf
from tensorflow import keras
from config import *
from mcts import MCTS
from tree import Tree

from state_manager import StateManager
from utils import normalize

class TOPP():

  def __init__(self, G=25):
    self.G = G # Number of games in a series
    self.modeldir = "./models"
    models = os.listdir(self.modeldir)
    models.sort(key=self.sortName)
    self.models = models
    print("Models:", self.models)

  def sortName(self, string):
    name = string.split(".")[0]
    iterations = name.split("-")[1]
    return int(iterations)    



  def load(self, filename):
    return keras.models.load_model("./{}/{}".format(self.modeldir, filename))

  def choose_best_move(self,predictions, legal_moves):
    best_move = None
    best_score = -1000
    for move in legal_moves:
      score = predictions[move]
      if score > best_score:
        best_move = move
        best_score = score
    return best_move
  
  def start_game(self, i, j):
    agt1 = self.load(self.models[i])
    agt2 = self.load(self.models[j])
    print("{} vs {}".format(self.models[i], self.models[j]))
    self.play_series(agt1,agt2)

  def start(self):
    results = []
    for i in range(len(self.models)):
      stats = []
      agt1 = self.load(self.models[i])
      for j in range(len(self.models)):
        agt2 = self.load(self.models[j])

        print("{} vs {}".format(self.models[i], self.models[j]))
        result = self.play_series(agt1, agt2)
        stats.append(result)
      results.append(stats)
    print("Results: ", results)
  
  def play_series(self, agt1, agt2):
    player1_wins = 0
    for i in range(self.G):
      print("[{}>{}]".format("-"*i, "."*(self.G - i - 1)), end="\r")
      sm = StateManager(5)

      while not sm.is_finished():
        player = sm.game.get_current_player() 
        state = np.array([np.concatenate((player,sm.game.board), axis=None)])
        if player == 1:
          predictions = agt1.predict(state)[0]
        else:
          predictions = agt2.predict(state)[0]
        
        legal_moves = sm.get_legal_moves()
        if len(sm.game.executedMoves) <= 1:
          best_move = random.choice(legal_moves)
        else:
          best_move = self.choose_best_move(predictions, legal_moves)
        sm.execute_move(best_move)


      if sm.get_winner() == 1:
        player1_wins += 1

    print("{} won {}/{} against {}.".format(agt1.name, player1_wins, self.G, agt2.name))
    print(np.reshape(sm.game.board, (boardsize,boardsize)))
    print(sm.game.executedMoves)
    return player1_wins

  def play_with_agents(self, agt1, agt2):
    player_turn = 1
    player1_wins = 0

    for i in range(self.G):
      print("[{}>{}]".format("-"*i, "."*(self.G - i - 1)), end="\r")
      sm = StateManager(5)
      agent = MCTS(exploration_rate=1, anet=agt1)
      game = sm.create_game()
      tree = Tree(game, chanceOfRandom=0.0)

      state = tree.root
      while not sm.is_finished():

        if player_turn == 1:
          agent.anet = agt1
          best_child = agent.uct_search(tree, state, num_search_games)
        else:
          agent.anet = agt2
          best_child = agent.uct_search(tree, state, num_search_games)
        
        game.execute_move(best_child.move)
        state = best_child


      if sm.get_winner() == 1:
        player1_wins += 1

    print("{} won {}/{} against {}.".format(agt1.name, player1_wins, self.G, agt2.name))
    print(np.reshape(sm.game.board, (boardsize,boardsize)))


    

topp = TOPP(5)
topp.start()