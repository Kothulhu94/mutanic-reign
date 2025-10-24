#!/usr/bin/env python3
"""
Generate all 120 skill .tres files for Mutant Reign
Based on Skill Design Spec v2.1
"""

import os
from pathlib import Path

# Base paths
SKILLS_DIR = Path("data/Skills")
SCRIPT_PATH = "res://Characters/Skill.gd"

# Standard XP progression
STANDARD_XP = "[0, 100, 100, 100, 500, 500, 500, 1000, 1000, 2000]"
STANDARD_MULTIPLIERS = "[1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0]"

def generate_uid(skill_name):
    """Generate a placeholder UID (will be replaced by Godot)"""
    import hashlib
    hash_val = hashlib.md5(skill_name.encode()).hexdigest()[:12]
    return f"uid://c{hash_val}"

def format_array(values):
    """Format array of floats for .tres file"""
    return "[" + ", ".join(str(v) for v in values) + "]"

def generate_skill_tres(skill_data):
    """Generate a .tres file content for a skill"""
    uid = generate_uid(skill_data["skill_id"])

    content = f"""[gd_resource type="Resource" script_class="Skill" load_steps=2 format=3 {uid}]

[ext_resource type="Script" path="{SCRIPT_PATH}" id="1"]

[resource]
script = ExtResource("1")
skill_id = &"{skill_data["skill_id"]}"
display_name = "{skill_data["display_name"]}"
description = "{skill_data["description"]}"
domain_id = &"{skill_data["domain_id"]}"
tier = {skill_data["tier"]}
max_rank = 10
primary_attribute = &"{skill_data["primary_attr"]}"
secondary_attribute = &"{skill_data["secondary_attr"]}"
primary_attr_scale = 0.75
secondary_attr_scale = 0.25
base_effect_per_rank = {format_array(skill_data["base_effect"])}
xp_per_rank = {STANDARD_XP}
effect_type = &"{skill_data["effect_type"]}"
is_multiplicative = {str(skill_data.get("is_multiplicative", True)).lower()}
is_passive = {str(skill_data.get("is_passive", True)).lower()}
effect_cap_per_rank = {format_array(skill_data.get("effect_cap", []))}
cooldown_cycles_per_rank = {format_array(skill_data.get("cooldowns", []))}
resource_cost_per_rank = {format_array(skill_data.get("costs", []))}
effect_multiplier_per_rank = {STANDARD_MULTIPLIERS}
xp_trigger = &"{skill_data["xp_trigger"]}"
xp_trigger_description = "{skill_data["xp_description"]}"
uses_difficulty_multiplier = {str(skill_data.get("uses_difficulty", True)).lower()}
prerequisite_skill_ids = {format_array(['&"' + p + '"' for p in skill_data.get("prerequisites", [])])}
unlocks_system = "{skill_data.get("unlocks", "")}"
"""
    return content

# ============================================================
# SKILL DEFINITIONS (All 120 skills)
# ============================================================

MELEE_SKILLS = [
    # Tier 1
    {
        "skill_id": "shield_discipline",
        "display_name": "Shield Discipline",
        "description": "Increases defensive capabilities in melee combat by +10% per rank.",
        "domain_id": "Melee",
        "tier": 1,
        "primary_attr": "Might",
        "secondary_attr": "Willpower",
        "base_effect": [0.10, 0.11, 0.12, 0.13, 0.14, 0.15, 0.16, 0.17, 0.18, 0.20],
        "effect_type": "defense_bonus",
        "xp_trigger": "blocking_attacks",
        "xp_description": "Gain XP when successfully blocking or parrying attacks"
    },
    {
        "skill_id": "aggressive_tactics",
        "display_name": "Aggressive Tactics",
        "description": "Grants +15% damage bonus when initiating combat (first strike).",
        "domain_id": "Melee",
        "tier": 1,
        "primary_attr": "Might",
        "secondary_attr": "Willpower",
        "base_effect": [0.15, 0.17, 0.19, 0.21, 0.23, 0.25, 0.27, 0.29, 0.31, 0.35],
        "effect_type": "first_strike_bonus",
        "xp_trigger": "initiating_combat",
        "xp_description": "Gain XP when attacking first in battle"
    },
    {
        "skill_id": "weapon_training",
        "display_name": "Weapon Training",
        "description": "General melee damage increase by +12% per rank.",
        "domain_id": "Melee",
        "tier": 1,
        "primary_attr": "Might",
        "secondary_attr": "Willpower",
        "base_effect": [0.12, 0.14, 0.16, 0.18, 0.20, 0.22, 0.24, 0.26, 0.28, 0.30],
        "effect_type": "melee_damage",
        "xp_trigger": "melee_combat",
        "xp_description": "Gain XP during melee combat encounters"
    },
    # Tier 2
    {
        "skill_id": "armor_piercing",
        "display_name": "Armor Piercing",
        "description": "Deal +25% damage against armored enemies, bypassing defenses.",
        "domain_id": "Melee",
        "tier": 2,
        "primary_attr": "Might",
        "secondary_attr": "Willpower",
        "base_effect": [0.25, 0.28, 0.31, 0.34, 0.37, 0.40, 0.43, 0.46, 0.49, 0.55],
        "effect_type": "armor_piercing_damage",
        "xp_trigger": "fighting_armored",
        "xp_description": "Gain XP when fighting heavily armored enemies",
        "prerequisites": ["weapon_training"]
    },
    {
        "skill_id": "flanking_commander",
        "display_name": "Flanking Commander",
        "description": "Companions can bypass enemy defenses when flanking.",
        "domain_id": "Melee",
        "tier": 2,
        "primary_attr": "Might",
        "secondary_attr": "Willpower",
        "base_effect": [1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0],
        "effect_type": "companion_flanking",
        "xp_trigger": "companion_flanking",
        "xp_description": "Gain XP when companions successfully flank enemies",
        "prerequisites": ["aggressive_tactics"]
    },
    {
        "skill_id": "battle_momentum",
        "display_name": "Battle Momentum",
        "description": "Gain +3% damage per consecutive victory (max 30%).",
        "domain_id": "Melee",
        "tier": 2,
        "primary_attr": "Might",
        "secondary_attr": "Willpower",
        "base_effect": [0.03, 0.033, 0.036, 0.039, 0.042, 0.045, 0.048, 0.051, 0.054, 0.06],
        "effect_type": "stacking_victory_bonus",
        "effect_cap": [0.30, 0.33, 0.36, 0.39, 0.42, 0.45, 0.48, 0.51, 0.54, 0.60],
        "xp_trigger": "consecutive_victories",
        "xp_description": "Gain XP when winning multiple battles in succession",
        "prerequisites": ["shield_discipline"]
    },
    # Tier 3
    {
        "skill_id": "melee_supremacy",
        "display_name": "Melee Supremacy",
        "description": "Master of close combat. +25% to all melee damage and defense.",
        "domain_id": "Melee",
        "tier": 3,
        "primary_attr": "Might",
        "secondary_attr": "Willpower",
        "base_effect": [0.25, 0.28, 0.31, 0.34, 0.37, 0.40, 0.43, 0.46, 0.49, 0.55],
        "effect_type": "all_melee_bonus",
        "xp_trigger": "melee_mastery",
        "xp_description": "Gain XP through sustained melee combat excellence",
        "prerequisites": ["armor_piercing", "flanking_commander", "battle_momentum"]
    },
    {
        "skill_id": "morale_shatterer",
        "display_name": "Morale Shatterer",
        "description": "Enemy morale drops 50% faster when facing you in melee.",
        "domain_id": "Melee",
        "tier": 3,
        "primary_attr": "Might",
        "secondary_attr": "Willpower",
        "base_effect": [0.50, 0.55, 0.60, 0.65, 0.70, 0.75, 0.80, 0.85, 0.90, 1.00],
        "effect_type": "enemy_morale_penalty",
        "xp_trigger": "breaking_morale",
        "xp_description": "Gain XP when causing enemies to flee or break formation",
        "prerequisites": ["melee_supremacy"]
    }
]

# Define all remaining domains...
# (I'll continue generating the rest)

def main():
    """Generate all skill files"""
    base_path = Path(__file__).parent

    # Create directory structure
    for domain in ["Melee", "Ranged", "ArtifactWeapons", "Exploration",
                   "Craftsmanship", "Trading", "Governance", "Leadership",
                   "Diplomacy", "Criminality", "Espionage", "Religion"]:
        domain_dir = base_path / SKILLS_DIR / domain
        domain_dir.mkdir(parents=True, exist_ok=True)

    # Generate Melee skills
    for skill in MELEE_SKILLS:
        filename = f"{skill['display_name'].replace(' ', '')}.tres"
        filepath = base_path / SKILLS_DIR / "Melee" / filename
        content = generate_skill_tres(skill)
        filepath.write_text(content, encoding="utf-8")
        print(f"Generated: {filepath}")

    print(f"\nGenerated {len(MELEE_SKILLS)} Melee skills")

if __name__ == "__main__":
    main()
