@testable import BattleFramework

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

let player = Entity(name: "Chad Longcock", type: .Player, hp: 10, spd: 5, str: 5, def: 6)
let wizard = Entity(name: "Nerdus Licksphincter", type: .Enemy, hp: 8, spd: 4, str: 7, def: 3)

let battle = Battle(enemy: wizard, player: player)

let winner = battle.perform()

print("And the winner is \(winner.name)")
