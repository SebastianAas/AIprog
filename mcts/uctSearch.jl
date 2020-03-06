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
    root::Node
    nodes::Dict{Node}
end

function uctSearch(tree::Tree, node::Node)
    game = node.game
    iterations = 0
    numIteration = 10
    while numIteration > iterations
        simulate(tree, node)
    end
    return selectMove(node)
end

function simulate(tree::Tree, node::Node)
    node = simTree(tree, node)
    score = simDefault(node)
    backup(node,score)
end

function simTree(tree::Tree, node::Node)
    c = 0.5 #Exploration constant
    t = 0
    game = deepcopy(node.game)
    while !isFinished(game) 
        if !(node in tree.nodes)
            newNode(node)
            return node
        end
        move = selectMove(node,c)
        executeMove!(game, move)
        t += 1
    end
    return node
end

function simDefault(board)
    while !isFinished(game)
        a = defaultPolicy(game)
        executeMove!(a)
    end
    return getResult(game)
end

function selectMove(node::Node, c)
    player = getCurrentPlayer(game)
    childValues = map(child -> child.score, node.children)
    if player == startingPlayer
        index = argmax(childValues)
    else 
        index = argmin(childValues)
    end
    return node.children[index].move
end

function backup!(node::Node, score)
    node.visits += 1
    node.score += score
    if node.parent != nothing
        backup!(node.parent, -score)
    end
end

function newNode(tree, node::Node)
    game = node.game
    possibleMoves = getMoves(game)
    for move in possibleMoves
        createNewNode(parent, move, game)
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