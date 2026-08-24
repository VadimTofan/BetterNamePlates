from pathlib import Path

from fontTools.ttLib import TTFont


FONT_PATH = Path("media/fonts/Expressway.ttf")
MAXIMUM_SIZE = 24_000
REQUIRED_TEXT = (
    "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
    "ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÑÒÓÔÕÖØÙÚÛÜÝßŒŸ"
    "àáâãäåæçèéêëìíîïñòóôõöøùúûüýÿœ"
    "¡¿€"
    "АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯ"
    "абвгдеёжзийклмнопрстуфхцчшщъыьэюя"
)

ALLOWED_CODEPOINTS = (
    set(range(0x0000, 0x0100))
    | {0x0152, 0x0153, 0x0178}
    | {0x0401, 0x0451}
    | set(range(0x0410, 0x0450))
    | set(range(0x2000, 0x2070))
    | set(range(0x20A0, 0x20D0))
    | set(range(0x2100, 0x2150))
    | set(range(0x2200, 0x2300))
)


# Describe: the bundled font supports WoW's Expressway-compatible locales.
def test_font_subset() -> None:
    # Given
    font = TTFont(FONT_PATH)
    unicode_codepoints: set[int] = set()

    for table in font["cmap"].tables:
        if table.isUnicode():
            unicode_codepoints.update(table.cmap)

    # When
    missing_characters = [
        character
        for character in REQUIRED_TEXT
        if ord(character) not in unicode_codepoints
    ]
    private_use_characters = [
        codepoint
        for codepoint in unicode_codepoints
        if 0xE000 <= codepoint <= 0xF8FF
    ]
    unsupported_characters = sorted(
        unicode_codepoints - ALLOWED_CODEPOINTS
    )

    # Then
    assert not missing_characters, (
        "missing required characters: " + "".join(missing_characters)
    )
    assert not private_use_characters, "private-use glyphs were not removed"
    assert not unsupported_characters, (
        "unsupported locale glyphs remain: "
        + ", ".join(
            f"U+{codepoint:04X}"
            for codepoint in unsupported_characters
        )
    )
    assert FONT_PATH.stat().st_size < MAXIMUM_SIZE, (
        "font file exceeds the optimized size limit"
    )


if __name__ == "__main__":
    test_font_subset()
    print("PASS preserves supported WoW locales in the Expressway subset")
