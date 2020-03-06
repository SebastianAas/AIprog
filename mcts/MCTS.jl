include("game.jl")
include("NIM.jl")
include("ledge.jl")

struct MCTSSolver
    "The game being played"
    game::Game

    "Number of iterations"
    iterations::Int64

    "Maximum rollout depth"
    depth::Int64

    "Specify how much the solver should explore"
    exploration::Float64
end

struct Node
    "Parent of the node"
    parent::Node

    "The game state of the Node"
    state

    "The move taken from the parent to this node"
    move::Move
    
    "The score of the node"
    score::Int

    "The times this nodes has been visited"
    visits::Int

    "The children of this node"
    children::Array{Node}
end

mutable struct MCTSTree
    "The root node of the tree"
    root::Node
    depth::Int
end

function initializeMCTSTree(depth::Int)::MCTSTree
    root = createNewNode(nothing, nothing)
    return MCTSTree(root,depth)
end

function resetSearch(tree::MCTSTree)
    tree.root = createNewNode(nothing, nothing)
end

"""
    search(tree,solver)

Single MCTS search: Selection-Expansion-Evaluation-Backpropagation
"""
function search(tree::MCTSTree, solver::MCTSSolver)
        node = selection(tree, tree.root)
        expansion!(tree,node)
        score = evaluation(tree,node)
        backpropagation!(tree,node,score)
end

"""
    selection(tree, node)

Finds a node that haven't been explored
"""
function selection(tree::MCTSTree,node::Node)::Node

    "Check if the node has not been seen before"
    if notExplored(node)
        return node
    end

    "Check if the state is final"
    if isLeafNode(node)
        return node
    end

    bestNode = nothing
    bestValue = nothing

    "Find the best child node / Find the best action"
    for child in parent.children
        nodeValue = calculateUCT(parent,child)
        if  (nodeValue >= bestValue)
            bestNode = child
            bestNodeValue = nodeValue
        end
    end
    return bestNode
end   

isLeafNode(node) = length(node.children) == 0
notExplored(node) = node.visits == 0

"Calculate Node value based on UCB (Upper Confidence Bound)"
calculateUCT(parent, child) = child.score / child.visits + 2 * sqrt(log(parent.visits) / child.visits)

"""
    expansion(tree, node)

Initialize new leaf node
"""
function expansion!(tree::MCTSTree, node::Node, solver::MCTSSolver)

    "Find all possible moves in the game"
    possibleMoves = solver.game.getMoves()
    for move in possibleMoves
        child = createNewNode(node,move)
        updateNodesChildren(node, child)
    end
end    


createNewNode(parent, move) = Node(parent,move,0,0,Node[])
updateNodesChildren(node, child) = push!(node.children, child)


"""
    evaluation(tree, node)

Leaf evaluation: Simulation/Rollout to a finished state and calculate the score
"""
function simulation(tree::MCTSTree, node::Node, solver::MCTSSolver)
    while !isFinished(solver.game)
        node = rolloutPolicy(node)
        solve.game.executeMove!(node.move)
    end
    return getResult(node)
end

rolloutPolicy(node::Node) = pickRandomMove(node)
pickRandomMove(node::Node) = rand(node.children)

function backpropagation!(node::Node, score::Int)
    updateNodeScore(node, score)
    updateNodeVisits(node)
    if getParent(node) != nothing
        backpropagation!(node.parent, -score)
    end
end

updateNodeVisits(node) = node.visits += 1
updateNodeScore(node, score) = node.sum += score 
getParent(node) = node.parent