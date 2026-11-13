# Dragon 2.0 generation prompt set

Tool: built-in `image_gen`; no image API or CLI fallback.
Identity references: approved simplified concept and canonical base.
The original detailed Dragon design is not used to ground the new rows.
Every later job uses both new references; direction families also use the
approved cardinal strip and completed standard contact sheet.

Shared prompt: a simplified adult anime white dragon woman with a large,
expressive violet-eyed face and a warm, gently playful older-sister presence.
Bold ivory crescent horns, curved forelock, white hair in a few broad locks,
pointed ears, compact lavender batlike wings with deep-violet edges, a smooth
thick white tail curved to screen-right, a simple ivory high-neck ankle dress
with one large waist knot, one lavender hem stripe, detached flowing sleeves
and white shoes. Thick clean deep-violet outlines and flat opaque cel shading.
No small scales, hair filigree, lace, embroidery, chains or repeated ornaments.
Constant body/head size, complete silhouettes, generous padding and green
gaps. Uniform bright green chroma staging. No text, props, floor, shadows,
motion lines, particles or detached effects. Preserve adult human posture.

| Source | Frames/layout | Acting direction |
| --- | --- | --- |
| idle | 6, 3 × 2 | Quiet breathing, slow blink, hands near waist, tiny wing/tail follow. |
| running-right | 8, 4 × 2 | Graceful rightward glide, upright torso, feet together, modest wingbeat. |
| running-left | 8, 4 × 2 | Independently generated leftward glide, trailing hair/skirt/tail; no running legs. |
| waving | 4, horizontal | Eye contact, restrained palm greeting, slight head inclination and tiny wink, return to rest. |
| jumping | 5, horizontal | Small celebratory lift: anticipation, airborne apex, descent, return; no deep crouch or kicking. |
| failed | 8, 4 × 2 | Brief concern and head inclination, soft exhale, reassuring smile and recovery. |
| waiting | 6, 3 × 2 | Attentive tilt, small offered palm, blink and gentle return smile. |
| running | 6, 3 × 2 | Upward thinking glance, fingertip at chin, contemplative tilt and knowing smile, hand lowers. |
| review | 6, 3 × 2 | Downward inspection scan, confirming nod and satisfied smile; hands near waist. |
| cardinals | 4, horizontal | Clear up/right/down/left head poses; torso anchored, eyes visible. Strengthen upward pitch. |
| look-first | 8, 4 × 2 | Coherent clockwise 000–157.5-degree family; head/eyes lead, torso stays fixed. |
| look-second | 8, 4 × 2 | Coherent 180–337.5-degree continuation matching first family and loop boundaries. |

Each state is generated separately. No whole-character turntables, mirrored
identity features, painted replacement eyes or manually drawn body parts.
R removes the staging background, extracts complete connected figures,
registers them at one scale per row and renders exact encoded previews.
