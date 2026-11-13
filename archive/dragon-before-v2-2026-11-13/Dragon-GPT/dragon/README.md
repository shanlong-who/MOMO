# Dragon for the chat application

This package uses the same local v2 pet export format as MOMO-GPT.

Extract `dragon-pet-v2.zip`. The `dragon` folder contains `pet.json` and
`spritesheet.webp`. Copy that complete folder into
`%USERPROFILE%\.codex\pets\dragon`, beside the existing `momo` folder.
Restart the application if needed, then select Dragon in its pet picker.
The application must support the same local pet format used by MOMO.

The package includes 73 frames: nine animation states and sixteen clockwise
look directions. The transparent atlas is 1536 × 2288 pixels, with 192 × 208
cells. Unused cells are empty.

`dragon/previews` contains motion GIFs. `contact-sheet.png`,
`look-directions.png` and `validation.json` provide review material.

The pet is animated by the host application. This export does not include a
separate language model or an API connection. It is a local export package;
it does not create a separate pet record in ChatGPT Work.

Artwork was generated from the user-supplied dragon-woman reference using the
built-in image generation tool. R prepares, assembles and checks the pixels.
The source and generation brief are in the sibling `Dragon-Source` folder.

This is a personal project, made for fun.
