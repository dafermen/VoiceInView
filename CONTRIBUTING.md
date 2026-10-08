# Contributing
Implement one approved phase at a time. Keep changes small and focused.
Swift: UpperCamelCase for types, lowerCamelCase for members, one primary type per file where practical.
Use SwiftUI and structured concurrency; introduce protocols only for meaningful service boundaries.
Verify Apple API signatures and availability against official documentation before implementation.
Use feat:, fix:, docs:, test:, refactor:, or chore: commits. Never commit signing material or secrets.
Every phase requires Xcode build, relevant tests, manual device checks, updated docs and architectural decisions.
Document failed or unavailable validation honestly; do not mark a phase complete based on static checks.
