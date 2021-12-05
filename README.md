# Frank's emoji

This is *Frank's emoji set*, an open content set of emoji implemented as Scalable Vector Graphics.

This project was inspired by the unexpected popularity of my [*thumbs up smiley*](https://openclipart.org/detail/28688/thumbs-up-smiley) that I've originally created just as an indicator to show web site visitors that their browser supports SVG. That graphic became my most popular work after I've published it on OpenClipart.org. Thus arose the idea of creating an emoji set in the same style. A version of the thumbs up smiley is included as a custom ZWJ sequence of smiling face and thumbs up gesture.


## Licensing

Licensing information is also included as RDF metadata in each SVG file.

The majority of the graphics are licensed under the [*CC BY-NC-SA 4.0*](http://creativecommons.org/licenses/by-nc-sa/4.0/) Licence.

All graphics in the [*flags*](./flags/index_Flags.md) directory as well as the custom emoji [*thumbs up smiley*](./emoji/U+263A-VS16-ZWJ-U+1F44D_smiling_face_giving_thumbs_up.svg) (which inspired the whole project) and [*frowning face giving thumbs down*](./emoji/U+2639-VS16-ZWJ-U+1F44E_frowning_face_giving_thumbs_down.svg) are under the [*CC0 1.0*](http://creativecommons.org/publicdomain/zero/1.0/) waiver.


## Codepoints

The filenames indicate which sequence of Unicode codepoints should be mapped to each graphic. This way a software that replaces emoji sequences in a text with code to embed the graphics could be configured from a file listing.

If a filename contains an underscore, then everything after the first underscore is a character name and the codepoint sequence is encoded in the part of the filename that precedes the first underscore.

Generally the codepoint sequence is represented by a hyphen-minus-joined sequence of representations for single codepoints.

The most general representation used for codepoints is identified by the prefix «U+» that is followed by the codepoint as a hexadecimal in uppercase and zero-padded to at least four digits.

For variation selectors there exists a shorter representation identified by the prefix «VS» that is followed by the decimal number of the variation selector. This is only used for «VS16» which selects the emoji variant of a character that defaults to text variant.

The zero-width joiner is represented by the abbreviation «ZWJ».

For flags there are specialised representations:

A filename consisting of two uppercase alphabetic characters is to be read as an ISO 3166-1 alpha-2 country code. The two characters in this case represent the corresponding regional indicator characters in the range U+1F1E6 to U+1F1FF.

A filename starting with two uppercase alphabetic characters followed by a hyphen-minus followed by one or more alphanumeric characters are interpreted as an ISO 3166-2 country subdivision code. This represents a sequence prefixed with the emoji character U+1F3F4 - waving black flag - followed by a sequence of formatting tag characters (in the ranges U+E0030 to U+E0039 and U+E0061 to U+E007A) corresponding to the alphanumeric characters in the filename (but converted to lowercase) and terminated by the cancel tag character, U+E007F.

Filenames of three lowercase characters are derived from ISO 639 language codes. They serve as identifiers for many ethnic flags. These are non-standard emoji and have no pre-defined codepoint sequences. The CSV file [flags/mapping-options.csv](flags/mapping-options.csv) lists mapping options for these. Currently suggested options are:

- ISO 3166-2 pseudo subdivision codes under the private use country code ZZ
- ZWJ emoji sequences based on the visual design of the flag

One outlier is rom-HU.svg . This filename is also based on a language code, but combined with a country code. It is conceptually the same flag as rom.svg, just in a variant design. I would not recommend mapping this to a separate code sequence but to have it replace rom.svg if it is preferred.
