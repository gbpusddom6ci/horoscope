# horoscope

## Local Secret Setup
1. `cp Config/Secrets.template.xcconfig Config/Secrets.xcconfig`
2. Add your keys to `Config/Secrets.xcconfig`.
3. In Xcode `horoscope` target Build Settings, fill:
`OPENROUTER_API_KEY`
`FREE_ASTRO_API_KEY`
4. Optional (debug): set the same values as Scheme environment variables.

Do not commit `Config/Secrets.xcconfig`.
