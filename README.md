
# Artificial Intelligence Programming

## Assignment 1

Create an agent which plays Peg Solitaire, using Actor-Critic Reinforcement learning. 
The code for the agent and Peg Solitaire can be found in the src directory.  

For the task I decided to try to use Julia and the machine learning framework Flux. 
As a novice Julia programmer, it was quite challenging to learn both the language and the task. 
Flux was a great framework, and quite intuitive to understand. 
Still, I had some difficulties getting the gradients for updating the actor and critic, 
but in the end I managed to get good results with the agent.

One of the difficulties with Julia, is the long start-up time for loading the packages. It can be improved by using a Jupyter Notebook, as you don't need to load in all the packages everytime you run the code. 

![alt-text](https://github.com/SebastianAas/AIprog/blob/master/assignment1/animations/animation.gif)

## Assignment 2
The goal of this assignment was to create a Monte-Carlo Tree Search reinforcement learning agent, which could play the game of Hex.


![alt-text](https://github.com/SebastianAas/AIprog/blob/master/src/animations/animation.gif)

## Assignment 3
This assignment was a continuation of assignment 2, but instead of only using Monte-Carlo Tree Search, it was implemented neural networks for simulating the rollout. 

