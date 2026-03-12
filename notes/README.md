This is `Lumina/Peonies`'s Obsidian vault for design choices, philosophies and concepts or even psuedocode. 
## Earlier iterations

`Lumina:Peonies:itr2` is the current and seemingly final iteration of this project, as of 2026. It uses a Rust server and Gleam/Lustre SPA as web frontend.

This project has been conceptualised and prototyped into many earlier iterations before, each with different approaches and final result. Some known older iterations had different names, listing a few:

| Codenamed        | About                                                                                                                                                                                                                                                                                                                                   | Introduced                                                          |
| ---------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------- |
| _Peonies-Lumina_ | factually `Lumina:Peonies:itr1`, had a much bigger approach where multiple backends were explored, including ones based on the BEAM (Gleam-Erlang backend to be precise), is what itr2 draws most inspiration of.<br><br>Having multiple backends with non-matching features proved to be too complicated to maintain or draw straight. | Federation, conceptually                                            |
| _Lumina-Ephew_   | A concept-only iteration that never made it past the drawing board.                                                                                                                                                                                                                                                                     | Lumina's principles and the global chronological timeline           |
| _Ephew_          | A near-complete PHP implementation with a plain HTML+CSS frontend (no scripts), fell apart due to the quickly aging PHP ecosystem at the time.                                                                                                                                                                                          | introducing the idea that 'multiple types of posts can feel native' |
| FNew             | A public text-only message pinboard                                                                                                                                                                                                                                                                                                     | ~~Criticism, mostly~~       |



The current iteration is a more well-documented and slower approach, giving time to learn and chances to refactor. It also comes in a time where the tech for it is perfect and 