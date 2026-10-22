## Setup

After cloning the repository, initialize and fetch git submodules (required for the `riscv-assembler` dependency in `vendor/riscv-assembler`):

```bash
git submodule update --init --recursive
```

Alternatively, clone with submodules in one step:

```bash
git clone --recurse-submodules <repository-url>
```

## Testing

```
cd rtl_tests && uv run make
```

## General TODOs

- [ ] Add linter and formatter, with standardized rules. This will help when the project starts growing.
- [ ] Add CI with linter, formattes, and tests.