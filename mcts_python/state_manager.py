from config import *
from game.hexgame import Hex
from game.viz_hex import print_board

class StateManager():

  def __init__(self, board_size):
    self.game = Hex(board_size)
  
  def create_game(self):
    game = Hex(boardsize)
    self.game = game
    return game

  def get_nn_state(self):
    return self.game.get_nn_state()
  
  def get_state(self):
    return self.game.board

  def get_legal_moves(self):
    return self.game.get_moves()

  def execute_move(self, move):
    self.game.execute_move(move)

  def get_winner(self):
    return self.game.get_winner()
  
  def is_finished(self):
    return self.game.is_finished()

  def print_board(self):
    print_board(self.get_state())
