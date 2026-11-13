# Generation brief and prompt set

Generator: built-in `image_gen`, not API or CLI fallback.
Identity inputs: `reference.png` (user's three-view design), `base.png`
(canonical generated full-body character). Every animation row is grounded
in both identity inputs. Direction rows also use approved cardinal poses and
the standard animation contact sheet; the second family uses the first family.

Shared constraints: adult anime white dragon woman, snowy long hair, ivory
segmented horns, elf ears, violet eyes, white high-neck long fantasy dress,
detached flowing sleeves, silver knot-flower ornaments, pale lavender wings,
white scaled tail curling screen-right. Opaque cel shading and clear outlines.
Full horns, wing tips, hands, hem, feet and tail inside frame. Constant scale,
generous separation and padding. No text, scenery, shadows, props, motion
lines, detached particles, floating symbols, glow or extra characters.

The canonical prompt asks for a compact readable full-body front-facing
desktop companion with gentle older-sister expression, preserving the supplied
design. The selected output retains the reference's normal anime proportions.

| Source | Frames/layout | Specific visual instruction |
| --- | --- | --- |
| idle | 6, 3 × 2 | Gentle breathing, blink, tiny hair, wing and tail sway; relaxed front-facing body. |
| running-right | 8, 4 × 2 | Screen-right walk cycle, alternating strides, modest dress movement and arm counter-swing. |
| running-left | 8, 4 × 2 | Independently generated screen-left cycle preserving asymmetric dress and ornaments. |
| waving | 4, horizontal | Screen-right hand rises, opens, waves and lowers; warm smile. |
| jumping | 5, horizontal | Standing, crouching, clearly airborne apex, descending, landed; preserve vertical offsets. |
| failed | 8, 4 × 2 | Mild disappointment, closed eyes, forehead/chest gesture and recovery. |
| waiting | 6, 3 × 2 | Clasped hands, inquisitive head tilt, blink and offered palm; asking for input. |
| running | 6, 3 × 2 | Planted feet, hand at chin, focused thinking, blink; no locomotion. |
| review | 6, 3 × 2 | Downward scanning gaze, hands at waist/sleeve, verifying nod and small smile. |
| cardinals | 4, horizontal | Up, screen-right, down, screen-left; torso anchored, head pitch/yaw and eyes lead. |
| look-first | 8, 4 × 2 | Clockwise 000 to 157.5 degrees in 22.5-degree steps; shared anchored body. |
| look-second | 8, 4 × 2 | Clockwise 180 to 337.5 degrees; continue first family with no boundary jump. |

Transparent backgrounds were requested where available. Some generated rows
contain alpha residue; other rows use saturated green staging to protect the
white hair and dress during deterministic background removal. Source revisions
are preserved separately and are not substituted for validated final pixels.
