# Phylodendron.jl

[![Build Status](https://travis-ci.com/eascarrunz/Phylodendron.svg?branch=master)](https://travis-ci.com/eascarrunz/Phylodendron)
[![Coverage Status](https://coveralls.io/repos/github/eascarrunz/Phylodendron/badge.svg?branch=master)](https://coveralls.io/github/eascarrunz/Phylodendron?branch=master)

## Description

A Julia package for the manipulation of phylogenetic trees. 

Trees are modelled as interlinked `Node` objects. Each node contains an array of links to its neighbours. Nodes are treated as directed (i.e. in a rooted tree, with parent and children) or undirected (i.e. as part of an unrooted tree) depending on an internal switch. Nodes of any degree are accepted, but there is no support for reticulations.

Work in progress!

Features implemented and **tested**:

- Linking and unlinking nodes
- Node labels
- Branch lengths and branch labels
- (Re)rooting, unrooting, and rooting with an outgroup
- Facilities for iterative traversals in preorder and postorder
- Parsing and writing Newick strings
- Generating trees by random addition sequence
- Grafting and snipping subtrees
- Finding paths between nodes
- Mapping nodes and data matrices to sets of species

Planned:

- Dedicated Tree object
- "Extra" fields in nodes, branches, and trees for storing any type of information
- Brownian motion models for continuous data (maybe in another package)

Under consideration:

- Topology comparisons by bipartitions
- Branch swapping by NNI, SPR, and TBR
- NEXUS format support