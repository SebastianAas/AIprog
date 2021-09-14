include("game.jl")
include("NIM.jl")
include("ledge.jl")

mutable struct MCTSSolver
    "The game being played"
    game::Game

    "Number of iterations"
    iterations::Int64

    "Maximum rollout depth"
    depth::Int64

    "Specify how much the solver should explore"
    exploration::Float64

end

mutable struct Node
    "Parent of the node"
    parent

    "The move taken from the parent to this node"
    move

    "The state of the game"
    game::Game
    
    "The score of the node"
    score::Int

    "The times this nodes has been visited"
    visits::Int

    "The children of this node"
    children::Array{Node}

    "Expanded"
    expanded::Bool

end

mutable struct MCTSTree
    "The root node of the tree"
    root::Node

    "Game being played"
    game::Game

    "Maximum depth of the tree"
    depth::Int

    "Number of search iterations"
    iterations::Int
end

function initializeMCTSTree(game::Game, iterations::Int)::MCTSTree
    root = createNewNode(nothing, nothing, game)
    return MCTSTree(root, game, 0, iterations)
end

function resetSearch!(tree::MCTSTree)
    tree.root = createNewNode(nothing, nothing)
end

"""
    search(tree,solver)

MCTS search: Selection-Expansion-Evaluation-Backpropagation
"""
function search(root::Node)
    iterations = 0
    while 10 > iterations
        println("iteration ", iterations)
        printTree(root)
        node = selection(root)
        if !(node.expanded); expansion!(node) end
        score = simulation(node)
        backpropagation!(node, score)
        iterations += 1
    end
    return selectBestChild(root)
end

"""
    selection(tree, node)

Finds a node that haven't been explored
"""
function selection(node::Node)::Node

    currentNode = node
    println("CurrentNode: ", currentNode.move)

    while !isTerminalNode(currentNode)

        if isLeafNode(currentNode)
            println("Current node ", currentNode.move)
            println(isTerminalNode(currentNode))
            return currentNode
        else
            println("Not leaf")
            println("node: ", currentNode.move)
            println("Numer of children ", length(currentNode.children))
            printChildren(currentNode)
            currentNode = selectBestChild(currentNode)
        end
    end
    return currentNode
end

function printChildren(node::Node)
    for (i,child) in enumerate(node.children)
        println("child $i: ", child.move, " Score: ", child.score)
    end
end

isLeafNode(node::Node) = length(node.children) == 0
isTerminalNode(node::Node) = isFinished(node.game)
notExplored(node::Node) = node.visits == 0

function selectBestChild(node::Node)

    bestNode = nothing
    bestValue = -Inf

    "Find the best child node / Find the best action"
    for child in node.children
        nodeValue = calculateUCT(node,child)
        if  (nodeValue >= bestValue)
            bestNode = child
            bestNodeValue = nodeValue
        end
    end
    return bestNode
end

"Calculate Node value based on UCB (Upper Confidence Bound)"
function calculateUCT(parent, child)
    UCT = 2 * sqrt(log(parent.visits) / max(child.visits,1))
    return child.score / max(child.visits,1) + UCT
end

"""
    expansion(tree, node)

Initialize new leaf node
"""
function expansion!(node::Node)

    node.expanded = true

    "Find all possible moves in the game"
    possibleMoves = getMoves(node.game)
    for move in possibleMoves
        gameState = deepcopy(node.game)
        executeMove!(gameState, move)
        child = createNewNode(node, move, gameState)
        updateNodesChildren(node, child)
    end
end 

createNewNode(parent, move, game) = Node(parent, move, game, 0, 0, Node[], false)
updateNodesChildren(node, child) = push!(node.children, child)


"""
    evaluation(tree, node)

Leaf evaluation: Simulation/Rollout to a finished state and calculate the score
"""
function simulation(node::Node)
    game = deepcopy(node.game)
    player = getCurrentPlayer(game)
    iterations = 0
    while !isFinished(game)
        possibleMoves = getMoves(game)
        move = rolloutPolicy(possibleMoves)
        executeMove!(game, move)
        iterations += 1
    end
    return getResult(game, player)
end

rolloutPolicy(possibleMoves) = pickRandomMove(possibleMoves)
pickRandomMove(possibleMoves) = rand(possibleMoves)

function backpropagation!(node::Node, score::Int)
    updateNodeScore(node, score)
    updateNodeVisits(node)
    if getParent(node) != nothing
        backpropagation!(node.parent, -score)
    end
end

updateNodeVisits(node) = node.visits += 1
updateNodeScore(node, score) = node.score += score
getParent(node) = node.parent


function printTree(node::Node, prefix="", last=true)
    output = last ? "`- " : "|- "
    println(prefix, output, node.move)
    prefix = string(prefix, last ? "   " : "|  ")
    for child in node.children
        last = child == node.children[end]
        printTree(child, prefix, last)
    end
end


