include("game.jl")
include("hex.jl")

mutable struct Node
    "Parent of the node"
    parent::Union{Nothing, Node}

    "The move taken from the parent to this node"
    move::Union{Nothing, Move}

    "The state of the game"
    game::Game
    
    "The score of the node"
    score::Float64

    "The times this nodes has been visited"
    visits::Int

    "The children of this node"
    children::Array{Node}

    "Unvisited children"
    #unvisitedChildren::Union{Nothing,Array{Move}}
end

mutable struct Tree
    "Root node"
    root::Node

    "Nodes in tree"
    nodes::Array{Node}

    "Number of rollouts"
    numberOfRollouts::Int

    "Exploration constant for the UCT"
    exploration::Float64

    "Neural network"
    neuralNet::Union{NeuralNet, Chain}

    "Neural network or random play"
    σ::Float64
end


function newTree(game::Game, neuralNet::Union{NeuralNet, Chain}, σ::Float64)::Tree
	root = createNewNode(nothing, nothing, game)
    tree = Tree(root, [], gameSimulator.M, exploration, neuralNet, σ)
    return tree
end

"Search"
function search!(tree::Tree, node::Node)
    iterations = 0
    game = deepcopy(node.game)
    while tree.numberOfRollouts >= iterations
        simulate!(tree, node)
        iterations += 1
    end
    node.game = game
    return treePolicy(node)
end

function simulate!(tree::Tree, node::Node)
    node = simTree(tree, node)
    score = simDefault(tree, node.game)
    backup!(node,score)
end

"Selection"
function simTree(tree::Tree, node::Node)::Node
    c = tree.exploration #Exploration constant
    game = deepcopy(node.game)
    while !isFinished(game) 
        if !(node in tree.nodes)
            newNode!(tree,node)
            return node
        end
        node = selectMove(tree, node, c, false) 
        executeMove!(game, node.move)
    end
    return node
end

"Rollout / Evaluation"
function simDefault(tree::Tree, game::Game)::Int
    game = deepcopy(game)
    while !isFinished(game)
        if tree.σ > rand()
            a = pickRandomMove(game)
        else
            a = targetPolicy(tree, game)
        end
        executeMove!(game, a)
    end
    result = getResult(game)
    return result
end

function treePolicy(node::Node)::Node
    childVisits = map(child -> child.visits, node.children)
    return node.children[argmax(childVisits)]
end

function pickRandomMove(game::Game)::Move
    possibleMoves = getMoves(game)
    return rand(possibleMoves)
end

function targetPolicy(tree::Tree, game::Game)::Move
    currentPlayer = getCurrentPlayer(game)
    evaluation = tree.neuralNet(vcat(currentPlayer,vec(permutedims(game.board))))
    bestMove = chooseBestPossibleMove(game, evaluation)
    return bestMove
end

function chooseBestPossibleMove(game::Game, evaluation::Union{Array{Float32},CuArray{Float32,1,Nothing}})::Move
    bestMove = nothing
    bestScore = -Inf
    possibleMoves = getMoves(game)
    for move in possibleMoves
        i = coordToPoint(game, move)
        score = evaluation[i]
        if score > bestScore
            bestMove = move
            bestScore = score
        end
    end
    return bestMove
end


function selectMove(tree::Tree, node::Node, c::Float64, t)::Node
    game = node.game
    player = getCurrentPlayer(game)
    legalMoves = map(child -> coordToPoint(node.game, child.move), node.children)
    #evaluation = normalizeNNOutput(tree.neuralNet(cat(dims=4,game.board)), legalMoves)
    #if t
        #println(evaluation)
    #end
    positive = player == game.startingPlayer
    childValues = map(child -> calculateUCT(node, child, c, positive), node.children)
    if player === game.startingPlayer
        index = argmax(childValues)
    else 
        index = argmin(childValues)
    end
    return node.children[index]
end

"Calculate Node value based on PUCT"
function calculatePUCT(parent, child::Node, c, evaluation, positive)::Float64
    i = coordToPoint(child.game, child.move)
    UCT = c * evaluation[i] * sqrt(log(parent.visits) / (child.visits + 1))
    return positive ? child.score/max(child.visits,1) + UCT : child.score/max(child.visits,1) - UCT
end

"Calculate Node value based on UCT"
function calculateUCT(parent, child::Node, c, positive)::Float64
    UCT = c * sqrt(log(parent.visits) / (child.visits + 1))
    return positive ? child.score + UCT : child.score - UCT
end

function normalizeNNOutput(evaluation, legalMoves)
    for i in (1:length(evaluation))
        if !(i in legalMoves)
            evaluation[i] = 0
        end
    end
    total = sum(evaluation)
    return map(x -> x/total, evaluation)
end
    

"Backpropagation"
function backup!(node::Node, score::Int)
    node.visits += 1
    node.score += (score - node.score) / node.visits  
    if node.parent != nothing
        backup!(node.parent, score)
    end
end

"Expansion"
function newNode(tree::Tree, node::Node)
    if node.unvisitedChildren == nothing
        println("this happens")
        possibleMoves = getMoves(node.game)
        node.unvisitedChildren = possibleMoves
    end
    if length(node.unvisitedChildren) == 0
        println("no more children")
        push!(tree.nodes, node)
    end
    if length(node.unvisitedChildren) != 0
        println("this happens too")
        move = rand(node.unvisitedChildren)   
        game = deepcopy(node.game)
        executeMove!(game, move)
        n = createNewNode(node, move, game)
        push!(node.children, n)
    end
end

function newNode!(tree::Tree, node::Node)
    possibleMoves = getMoves(node.game)
    push!(tree.nodes, node)
    for move in possibleMoves
        game = deepcopy(node.game)
        executeMove!(game, move)
        n = createNewNode(node, move, game)
        push!(node.children, n)
    end
end

function createNewNode(parent::Union{Node,Nothing}, move::Union{Move,Nothing}, game::Game)::Node
    return Node(parent, move, game, 0.0, 0, Node[])
end


function printTree!(node::Node, prefix="", last=true)
    output = last ? "`- " : "|- "
    println(prefix, output, node.move, " Score: ", node.score, " Visits: ", node.visits)
    prefix = string(prefix, last ? "   " : "|  ")
    for child in node.children
        last = child == node.children[end]
        printTree!(child, prefix, last)
    end
end