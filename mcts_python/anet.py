import os
import tensorflow as tf
from tensorflow import keras
import random
from config import hidden_layer_sizes
import numpy as np
from utils import normalize
import pandas as pd

seed_value = 69

""" Set all seed values to get reproducible results """
# os.environ['PYTHONHASHSEED']=str(seed_value)
# random.seed(seed_value)
# np.random.seed(seed_value)
# tf.random.set_seed(seed_value)

class ANET():

  def __init__(self, boardsize):
    self.boardsize = boardsize
    self.model = self.get_model()
  
  def get_model(self):
    # TODO: If model exists load model, else create a new one
    return self.generate_model()

  def predict(self, data):
    return self.model(data)

  def generate_model(self):
    # Create the network
    model = keras.Sequential()

    # Add the first layer
    model.add(keras.layers.Dense(self.boardsize**2 + 1, input_shape=(self.boardsize**2 +1, )))

    # Add hidden layers
    for layer_size in hidden_layer_sizes:
      model.add(keras.layers.Dense(layer_size, activation='relu'))
    
    # Add output layer
    model.add(keras.layers.Dense(self.boardsize**2, activation="softmax"))

    # Compile the model
    model.compile(
      optimizer="ADAM",
      loss=tf.keras.losses.MSE,
      metrics=['accuracy']
    )
    return model
  
  def choose_move(self, board):
    state = np.array([list(board.get_nn_state())])
    predictions = self.model.predict(state)[0]
    normalized = self.normalize_predictions(board, predictions)
    return board.get_legal_moves()[np.argmax(normalized)]

  def normalize_predictions(self, board, predictions):
    state = board.get_nn_state()
    indices_to_remove = []
    for i in range(len(predictions)):
      if state[i+1] != 0:
        indices_to_remove.append(i)
    
    legal_predictions = np.delete(predictions, indices_to_remove)
    return normalize(legal_predictions)

  def split_cases(self, cases):
    return zip(*cases)

  def train(self, x_train, y_train):
    self.model.fit(x_train, y_train, epochs=3)

def string_to_array(string):
  s = string.replace("[", "")
  s = s.replace("]", "")
  a = s.split(",")
  a = [float(i) for i in a]
  return np.asarray(a) 


