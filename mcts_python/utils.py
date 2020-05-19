import numpy as np
import timeit

def normalize(a):
  total = np.sum(a)
  return np.array(a)/total

def softmax(x):
  return np.exp(x) / np.sum(np.exp(x), axis=0)

class Timer():
  
  def start(self, label=None):
    self.label=label
    self.start_time = timeit.default_timer()
  
  def stop(self):
    self.duration = timeit.default_timer() - self.start_time
    print("Time to execute '{}':{}".format(self.label, self.duration))
