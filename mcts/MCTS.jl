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
    root = creteNewNode(nothing, nothing)
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
    iterations = 0
    while solver.iterations > iterations 

        "Selection"
        node = selection(tree, tree.root)

        if isFinished(solver.game)
            return getOutcome(solver.game)
        end

        if isLeafNode(node)
            return getOutcome(solver.game)
        end


        "Expansion"
        expansion!(tree,node)

        "Evaluation"
        score = evaluation(tree,node)

        "Backpropagation"
        backpropagation!(tree,node,score)

        iterations += 1
    end

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
        nodeValue = calculateNodeUCT(parent,child)
        if  (nodeValue >= bestValue)
            bestNode = child
            bestNodeValue = nodeValue
        end
    end

    return bestNode 
end   

isLeafNode(node) = length(node.children) == 0
notExplored(node) = node.visits == 0

"""
Calculate Node value based on UCB (Upper Confidence Bound)

"""
function calculateUCT(parent, child)
    return child.score/child.visits + 2*sqrt(parent.visits/child.visits)
end



"""
    expansion(tree, node)

Initialize new leaf node
"""
function expansion!(tree::MCTSTree, node::Node)

    "Find all possible moves in the game"
    possibleMoves = tree.game.getMoves()
    for move in possibleMoves
        child = createNewNode(node,move)
        updateNodeChildren(node, child)
    end
end    


createNewNode(parent, move) = Node(parent,move,0,0,Node[])
updateNodeChildren(node, child) = push!(node.children, child)


"""
    evaluation(tree, node)

Leaf evaluation: Rollout to a leaf node and calculate the score
"""
function evaluation(tree::MCTSTree, node::Node)
    score = nothing
end



function backpropagation!(tree::MCTSTree, node::Node, score)
    if isFinished(tree.game)
        score = getScore(tree.game)
        updateNodeScore(node, score)
        updateNodeVisits(node)
        backpropagation!(getParent(node), -score)
    else
        updateNodeScore += score
        updateNodeVisits(node)

        if getParent(node) != nothing

        end
    end
end

updateNodeVisits(node) = node.visits += 1
updateNodeScore(node, score) = node.sum += score 
getParent(node) = node.parent

