# Metrics

## VERSION 
0.9.7 (Beta)

## DESCRIPTION
Metrics is an addon that collects personal encounter combat performance metrics. In this context 'personal' means that the encounter metrics are collected for a single character (UnitName("Player) and the character's pet, UnitName("Pet), if any). For the purposes of data collection, an encounter is defined as the time over which a single character (includng its pet) engages with, and successfully beats, one or more enemy NPCs. Combat ends when he last NPC dies.

What differentiates Metrics from other combat-oriented addons its ability to collect accurate combat metrics from target dummies. 

Why is this important? 

Since Blizzard's combat dummies do not die, the time that the encounter ends cannot be easily determined. This is unlike live encounters. When enemy MOBs die a "UNIT_DIED" or a "PARTY_KILL" event is fired. Combat loggers use these two events to determine explicitly when an encounter ends.

Metrics uses a similar mechanism, but instead simulates a health bar that maps to a target dummy. When the health bar [of the last standing MOB/NPC] reaches zero (simulating the target's death) the encounter ends.
