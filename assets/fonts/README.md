# Bundled reading fonts

The app bundles these fonts for offline reading. IBM Plex Sans remains the
default and interface font; Newsreader remains the editorial heading font.
Choosing a reading font changes only the focused word and paused word list.

| Reading font | Source | License |
| --- | --- | --- |
| IBM Plex Sans | Approved `phralio-brandkit/fonts/IBMPlexSans.ttf` | [OFL](IBMPlexSans-OFL.txt) |
| Newsreader | Approved `phralio-brandkit/fonts/Newsreader.ttf` | [OFL](Newsreader-OFL.txt) |
| Inter | [Google Fonts](https://github.com/google/fonts/tree/23e54b51ddffbc7713c583748e3bd86f62b1fa4a/ofl/inter) | [OFL](Inter-OFL.txt) |
| Roboto | [Google Fonts](https://github.com/google/fonts/tree/23e54b51ddffbc7713c583748e3bd86f62b1fa4a/ofl/roboto) | [OFL](Roboto-OFL.txt) |
| Open Sans | [Google Fonts](https://github.com/google/fonts/tree/23e54b51ddffbc7713c583748e3bd86f62b1fa4a/ofl/opensans) | [OFL](OpenSans-OFL.txt) |
| Montserrat | [Google Fonts](https://github.com/google/fonts/tree/23e54b51ddffbc7713c583748e3bd86f62b1fa4a/ofl/montserrat) | [OFL](Montserrat-OFL.txt) |
| Nunito Sans | [Google Fonts](https://github.com/google/fonts/tree/23e54b51ddffbc7713c583748e3bd86f62b1fa4a/ofl/nunitosans) | [OFL](NunitoSans-OFL.txt) |
| Merriweather | [Google Fonts](https://github.com/google/fonts/tree/23e54b51ddffbc7713c583748e3bd86f62b1fa4a/ofl/merriweather) | [OFL](Merriweather-OFL.txt) |
| Source Sans 3 | [Google Fonts](https://github.com/google/fonts/tree/23e54b51ddffbc7713c583748e3bd86f62b1fa4a/ofl/sourcesans3) | [OFL](SourceSans3-OFL.txt) |
| Noto Sans | [Google Fonts](https://github.com/google/fonts/tree/23e54b51ddffbc7713c583748e3bd86f62b1fa4a/ofl/notosans) | [OFL](NotoSans-OFL.txt) |

The eight Google Fonts TTFs and license files are unmodified from upstream
revision `23e54b51ddffbc7713c583748e3bd86f62b1fa4a`. The two brandkit
fonts and their original licenses are preserved. Flutter uses bundled Noto Sans
and platform fallbacks for glyphs absent from a selected family. CJK glyphs
continue to use native platform fallback fonts.
