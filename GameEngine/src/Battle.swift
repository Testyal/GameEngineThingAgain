//
//  Battle.swift
//  BetterCountdownTimer
//
//  Created by Billy Sumners on 17/01/2020.
//  Copyright © 2020 Billy Sumners. All rights reserved.
//

import Foundation

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

struct AttackOutcome {
    
    let attacker: Entity
    let defender: Entity
    
    enum Summary {
        case AttackerWins
        case DefenderWins
        case NobodyWins
    }
    
    var summary: Summary {
        if attacker.hp <= 0 {
            return .DefenderWins
        } else if defender.hp <= 0 {
            return .AttackerWins
        } else {
            return .NobodyWins
        }
    }
    
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

public struct Entity {
    
    enum EntityType {
        case Player
        case Enemy
    }
    
    let name: String
    let type: EntityType
    
    let hp: Int
    let spd: Int
    let str: Int
    let def: Int
    
    func attack(defender: Entity) -> AttackOutcome {
        let newDefenderHP = defender.hp - max(0, self.str - defender.def)
        let newDefender = Entity(name: defender.name, type: defender.type, hp: newDefenderHP, spd: defender.spd, str: defender.str, def: defender.def)
        
        return AttackOutcome(attacker: self, defender: newDefender)
    }
    
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

public class Battle {
    
    let enemy: Entity
    let player: Entity
    let battleInput: BattleInput
    
    init(enemy: Entity, player: Entity) {
        self.enemy = enemy
        self.player = player
        
        self.battleInput = BattleInput(player: self.player, spells: ["attack": player.attack])
    }
    
    func perform() -> Entity {
        func performBattle(attacker: Entity, defender: Entity) -> Entity {
            let spell: BattleInput.Spell
            if attacker.type == .Player {
                spell = self.battleInput.spells["attack"]!
            } else {
                spell = attacker.attack
            }
            
            let outcome = spell(defender)
            
            switch outcome.summary {
            case .AttackerWins: return outcome.attacker
            case .DefenderWins: return outcome.defender
            case .NobodyWins: return performBattle(attacker: outcome.defender, defender: outcome.attacker)
            }
        }
        
        let (initialAttacker, initialDefender) = player.spd >= enemy.spd ? (player, enemy) : (enemy, player)
        
        return performBattle(attacker: initialAttacker, defender: initialDefender)
    }
    
    static func determineWinnerOfBattle(between attacker: Entity, and defender: Entity) -> Entity {
        let attackResults = attacker.attack(defender: defender)
        
        switch attackResults.summary {
        case .AttackerWins: return attacker
        case .DefenderWins: return defender
        case .NobodyWins: return determineWinnerOfBattle(between: attackResults.attacker, and: attackResults.defender)
        }
    }
    
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

public class BattleInput {
    
    typealias Spell = (Entity) -> AttackOutcome
    typealias Spellbook = [String: Spell]
    
    let player: Entity
    let spells: Spellbook
    
    init(player: Entity, spells: Spellbook) {
        self.player = player
        self.spells = spells
    }
    
    func askSpellInput() -> Spell? {
        return nil
    }
    
}

