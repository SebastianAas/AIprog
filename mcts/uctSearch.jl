include("NIM.jl")
include("Ledge.jl")
include("game.jl")


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
end

mutable struct Tree
    "Root node"
    root::Node

    "Nodes in tree"
    nodes::Array{Node}
end

function uctSearch(tree::Tree, node::Node)::Node
    game = node.game
    iterations = 0
    numIteration = 100
    while numIteration > iterations
        simulate(tree, node)
        iterations += 1
    end
    return selectMove(node, 0)
end

function simulate(tree::Tree, node::Node)
    node = simTree(tree, node)
    score = simDefault(deepcopy(node.game))
    backup!(node,score)
end

function simTree(tree::Tree, node::Node)::Node
    c = 0.5 #Exploration constant
    t = 0
    game = deepcopy(node.game)
    while !isFinished(game) 
        if !(node in tree.nodes)
            newNode(tree,node)
            return node
        end
        node = selectMove(node,c)
        executeMove!(game, node.move)
        t += 1
    end
    return node
end

"Rollout"
function simDefault(game)::Int
    while !isFinished(game)
        possibleMoves = getMoves(game)
        a = defaultPolicy(possibleMoves)
        executeMove!(game, a)
    end
    return getResult(game)
end

defaultPolicy(possibleMoves) = pickRandomMove(possibleMoves)
pickRandomMove(possibleMoves) = rand(possibleMoves)

function selectMove(node::Node, c)::Node
    game = node.game
    player = getCurrentPlayer(game)
    childValues = map(child -> child.score, node.children)
    if player == game.startingPlayer
        index = argmax(childValues)
    else 
        index = argmin(childValues)
    end
    return node.children[index]
end

function backup!(node::Node, score)
    node.visits += 1
    node.score += score
    if node.parent != nothing
        backup!(node.parent, -score)
    end
end

function newNode(tree::Tree, node::Node)
    push!(tree.nodes, node)
    possibleMoves = getMoves(node.game)
    for move in possibleMoves
        game = deepcopy(node.game)
        executeMove!(game, move)
        n = createNewNode(node, move, game)
        push!(node.children, n)
    end
end

createNewNode(parent, move, game) = Node(parent, move, game, 0, 0, Node[])

function printTree(node::Node, prefix="", last=true)
    output = last ? "`- " : "|- "
    println(prefix, output, node.move)
    prefix = string(prefix, last ? "   " : "|  ")
    for child in node.children
        last = child == node.children[end]
        printTree(child, prefix, last)
    end
end