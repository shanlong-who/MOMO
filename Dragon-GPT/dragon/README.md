# Dragon 2.0 for the desktop chat application

This is the simplified, graceful edition approved in the design review.
It uses the same local v2 pet package format as the existing MOMO and MIMI.

Extract `dragon-pet-v2.zip`. Copy the complete `dragon` folder to
`%USERPROFILE%\.codex\pets\dragon`. If an older Dragon is already installed,
preserve that folder before replacing it. In the desktop app, open
Settings > Pets, select Refresh, then choose Dragon.
See the [official Pets documentation](https://learn.chatgpt.com/docs/pets).

The artwork has a larger face, crescent horns, lavender wings, a smooth
crescent tail and a simple white dress. Human gestures include a restrained
palm greeting and wink, a thoughtful chin gesture, an attentive nod, and
concern followed by reassurance. Directional movement is a graceful glide.

The transparent 1536 × 2288 lossless WebP uses 192 × 208 cells. It contains
57 standard animation frames, sixteen gaze frames and one neutral cell.
As in the supplied local MOMO/MIMI packages, the neutral pose occupies idle
row column 6, outside its six-frame animation loop. The remaining fourteen
cells are fully transparent. The package is checked against the local
desktop convention used by the supplied MOMO and MIMI packages.

`dragon/previews` contains state loops, an all-state timeline, labeled stills,
an idle-to-lift transition and an ordered gaze loop. The previews show the
intended Offline cadence; the desktop chat application controls its own
playback timing and activity triggers.

This export does not create a remote ChatGPT Work pet record or activate a
pet. It contains no separate language model or API connection.

Artwork was made with the built-in image generation tool from the approved
simplified concept. R extracts, cleans, registers, assembles and validates
the generated pixels. See the sibling `Dragon-Source` folder for source,
generation prompts and QA records. This is a personal project, made for fun.
