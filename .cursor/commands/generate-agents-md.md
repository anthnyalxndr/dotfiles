# generate-agents-md

---

## description: Generate an agents.md file by exploring the codebase

# Generate agents.md

Create or update an `agents.md` file that helps AI coding agents understand and work effectively with this project.

## Instructions

Follow these phases to explore the codebase and produce comprehensive documentation:

### Phase 1: Codebase Discovery

1. **Read the dependency manifest** to understand the tech stack:
    - JavaScript/TypeScript: `package.json`
    - Python: `requirements.txt`, `pyproject.toml`
    - Rust: `Cargo.toml`
    - Go: `go.mod`

2. **Examine project structure** - list root and key subdirectories to identify:
    - Source code location (`src/`, `app/`, `lib/`)
    - Test directories (`test/`, `tests/`, `__tests__/`)
    - Configuration files

3. **Find entry points** that reveal application structure:
    - Route definitions (web apps)
    - Main/index files
    - CLI entry points

4. **Read existing documentation** (`README.md`, inline comments, docs/)

5. **Identify patterns** by scanning representative files for:
    - Code style and naming conventions
    - Common abstractions
    - Import organization

### Phase 2: Generate agents.md

Create the file with these sections (adapt based on project complexity):

```markdown
# Coding Agent Guide

## Project Overview

### What This Project Does

[One paragraph: business purpose, problem solved, target users]

### Mental Model

[Key concepts and domain terms - how to think about this system]

### Tech Stack

- **Language**: [Primary language and version]
- **Framework**: [Main framework]
- **Key Libraries**: [Important dependencies]

### Architecture

[ASCII diagram showing component relationships]

### Key Directories

| Directory | Purpose       |
| --------- | ------------- |
| `src/`    | [Description] |

---

## Development Setup

### Prerequisites

[Required tools and versions]

### Getting Started

[Installation and run commands]

### Environment Variables

[Required configuration]

---

## Coding Standards

### File Naming

| Type | Convention | Example |
| ---- | ---------- | ------- |

### Code Patterns

[Preferred patterns with examples]

### Import Organization

[Order and grouping]

---

## Testing

### Running Tests

[Commands]

### Test Patterns

[How to structure tests]

---

## Common Pitfalls

1. **[Pitfall]**: [How to avoid]
2. **[Pitfall]**: [How to avoid]

---

## Key Abstractions

[Important utilities, hooks, or patterns reused across the codebase]
```

### Phase 3: Writing Guidelines

- **Be concrete**: Use real file paths, actual code examples
- **Be actionable**: Every section should help complete coding tasks
- **Use visuals**: ASCII diagrams, tables, code blocks
- **Prioritize**: What helps agents add features following existing patterns

### Phase 4: Adapt by Project Type

**Frontend**: Component organization, state management, routing, styling
**Full-Stack**: Add API routes, data fetching, server/client separation
**Backend/API**: Endpoints, auth, database, error handling
**CLI**: Commands, argument parsing, output formatting
**Library**: Public API, exports, versioning

## Checklist

Before finishing, verify:

- [ ] Project purpose is clear in 1-2 sentences
- [ ] Tech stack documented with versions
- [ ] Directory structure explained
- [ ] Setup instructions complete
- [ ] Coding conventions have examples
- [ ] Common patterns documented
- [ ] Testing approach explained
- [ ] 2-3 common pitfalls noted
