include("NIM.jl")
include("Ledge.jl")
include("game.jl")

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
end


function newTree(game::Game)::Tree
	root = createNewNode(nothing, nothing, game)
    tree = Tree(root, [], gameSimulator.M, exploration)
    return tree
end

"Search"
function uctSearch(tree::Tree, node::Node)::Node
    iterations = 0
    game = deepcopy(node.game)
    while tree.numberOfRollouts >= iterations
        simulate!(tree, node)
        iterations += 1
    end
    node.game = game
    return selectMove(node, 0.0)
end

function simulate!(tree::Tree, node::Node)
    node = simTree(tree, node)
    score = simDefault(node.game)
    backup!(node,score)
end

"Selection"
function simTree(tree::Tree, node::Node)::Node
    c = tree.exploration #Exploration constant
    t = 0
    game = deepcopy(node.game)
    while !isFinished(game) 
        if !(node in tree.nodes)
            newNode!(tree,node)
            return node
        end
        node = selectMove(node,c)
        executeMove!(game, node.move)
        t += 1
    end
    return node
end

"Rollout / Evaluation"
function simDefault(game)::Int
    game = deepcopy(game)
    while !isFinished(game)
        possibleMoves = getMoves(game)
        a = defaultPolicy(possibleMoves)
        executeMove!(game, a)
    end
    result = getResult(game)
    return result
end

defaultPolicy(possibleMoves) = pickRandomMove(possibleMoves)
pickRandomMove(possibleMoves) = rand(possibleMoves)

function selectMove(node::Node, c::Float64)::Node
    game = node.game
    player = getCurrentPlayer(game)
    positive = player == game.startingPlayer
    childValues = map(child -> calculateUCT(node, child, c, positive), node.children)
    if player === game.startingPlayer
        index = argmax(childValues)
    else 
        index = argmin(childValues)
    end
    return node.children[index]
end

"Calculate Node value based on UCB (Upper Confidence Bound)"
function calculateUCT(parent, child::Node, c, positive)::Float64
    UCT = c * sqrt(log(parent.visits) / (child.visits + 1))
    return positive ? child.score + UCT : child.score - UCT
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
function newNode!(tree::Tree, node::Node)
    push!(tree.nodes, node)
    possibleMoves = getMoves(node.game)
    for move in possibleMoves
        game = deepcopy(node.game)
        executeMove!(game, move)
        n = createNewNode(node, move, game)
        push!(node.children, n)
    end
end

createNewNode(parent, move, game)::Node = Node(parent, move, game, 0.0, 0, Node[])


function printTree!(node::Node, prefix="", last=true)
    output = last ? "`- " : "|- "
    println(prefix, output, node.move, " Score: ", node.score, " Visits: ", node.visits)
    prefix = string(prefix, last ? "   " : "|  ")
    for child in node.children
        last = child == node.children[end]
        printTree!(child, prefix, last)
    end
end